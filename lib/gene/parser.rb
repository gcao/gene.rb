require 'strscan'

module Gene
  class Parser < StringScanner
    STRING                = /" ((?:[^\x0-\x1f"\\] |
                              # escaped special characters:
                              \\["\\\/bfnrt] |
                              \\u[0-9a-fA-F]{4} |
                              # match all but escaped special characters:
                              \\[\x20-\x21\x23-\x2e\x30-\x5b\x5d-\x61\x63-\x65\x67-\x6d\x6f-\x71\x73\x75-\xff])*)
                            "/nx
    INTEGER               = /(-?0|-?[1-9]\d*)/
    FLOAT                 = /(-?
                              (?:0|[1-9]\d*)
                              (?:
                                \.\d+(?i:e[+-]?\d+) |
                                \.\d+ |
                                (?i:e[+-]?\d+)
                              )
                              )/x
    ENTITY                = /([^\s\(\)\[\]\{\}]+)/
    GENE_OPEN             = /\(/
    GENE_CLOSE            = /\)/
    HASH_OPEN             = /\{/
    HASH_CLOSE            = /\}/
    ARRAY_OPEN            = /\[/
    ARRAY_CLOSE           = /\]/
    TRUE                  = /true/
    FALSE                 = /false/
    NULL                  = /null/
    IGNORE                = %r(
      (?:
       //[^\n\r]*[\n\r]| # line comments
       /\*               # c-style comments
       (?:
        [^*/]|        # normal chars
        /[^*]|        # slashes that do not start a nested comment
        \*[^/]|       # asterisks that do not end this comment
        /(?=\*/)      # single slash before this comment's end
       )*
         \*/               # the End of this comment
         |[ \t\r\n]+       # whitespaces: space, horicontal tab, lf, cr
      )+
    )mx

    UNPARSED = Object.new

    # Creates a new JSON::Pure::Parser instance for the string _source_.
    #
    # It will be configured by the _opts_ hash. _opts_ can have the following
    # keys:
    # * *symbolize_names*: If set to true, returns symbols for the names
    #   (keys) in a JSON object. Otherwise strings are returned, which is also
    #   the default.
    # * *quirks_mode*: Enables quirks_mode for parser, that is for example
    #   parsing single JSON values instead of documents is possible.
    def initialize(source, opts = {})
      opts ||= {}
      unless @quirks_mode = opts[:quirks_mode]
        source = convert_encoding source
      end
      super source
      @symbolize_names = !!opts[:symbolize_names]
      @match_string = opts[:match_string]
    end

    alias source string

    def quirks_mode?
      !!@quirks_mode
    end

    def reset
      super
      @current_nesting = 0
    end

    # Parses the current JSON string _source_ and returns the complete data
    # structure as a result.
    def parse
      reset
      obj = nil
      if @quirks_mode
        while !eos? && skip(IGNORE)
        end
        if eos?
          raise ParserError, "source did not contain any JSON!"
        else
          obj = parse_value
          obj == UNPARSED and raise ParserError, "source did not contain any JSON!"
        end
      else
        until eos?
          case
          when scan(HASH_OPEN)
            obj and raise ParserError, "source '#{peek(20)}' not in JSON!"
            @current_nesting = 1
            obj = parse_hash
          when scan(ARRAY_OPEN)
            obj and raise ParserError, "source '#{peek(20)}' not in JSON!"
            @current_nesting = 1
            obj = parse_array
          when skip(IGNORE)
            ;
          else
            raise ParserError, "source '#{peek(20)}' not in JSON!"
          end
        end
        obj or raise ParserError, "source did not contain any JSON!"
      end
      obj
    end

    private

    def convert_encoding(source)
      if source.respond_to?(:to_str)
        source = source.to_str
      else
        raise TypeError, "#{source.inspect} is not like a string"
      end
      if defined?(::Encoding)
        if source.encoding == ::Encoding::ASCII_8BIT
          b = source[0, 4].bytes.to_a
          source =
            case
            when b.size >= 4 && b[0] == 0 && b[1] == 0 && b[2] == 0
              source.dup.force_encoding(::Encoding::UTF_32BE).encode!(::Encoding::UTF_8)
            when b.size >= 4 && b[0] == 0 && b[2] == 0
              source.dup.force_encoding(::Encoding::UTF_16BE).encode!(::Encoding::UTF_8)
            when b.size >= 4 && b[1] == 0 && b[2] == 0 && b[3] == 0
              source.dup.force_encoding(::Encoding::UTF_32LE).encode!(::Encoding::UTF_8)
            when b.size >= 4 && b[1] == 0 && b[3] == 0
              source.dup.force_encoding(::Encoding::UTF_16LE).encode!(::Encoding::UTF_8)
            else
              source.dup
            end
        else
          source = source.encode(::Encoding::UTF_8)
        end
        source.force_encoding(::Encoding::ASCII_8BIT)
      else
        b = source
        source =
          case
          when b.size >= 4 && b[0] == 0 && b[1] == 0 && b[2] == 0
            JSON.iconv('utf-8', 'utf-32be', b)
          when b.size >= 4 && b[0] == 0 && b[2] == 0
            JSON.iconv('utf-8', 'utf-16be', b)
          when b.size >= 4 && b[1] == 0 && b[2] == 0 && b[3] == 0
            JSON.iconv('utf-8', 'utf-32le', b)
          when b.size >= 4 && b[1] == 0 && b[3] == 0
            JSON.iconv('utf-8', 'utf-16le', b)
          else
            b
          end
      end
      source
    end

    # Unescape characters in strings.
    UNESCAPE_MAP = Hash.new { |h, k| h[k] = k.chr }
    UNESCAPE_MAP.update({
      ?"  => '"',
      ?\\ => '\\',
      ?/  => '/',
      ?b  => "\b",
      ?f  => "\f",
      ?n  => "\n",
      ?r  => "\r",
      ?t  => "\t",
      ?u  => nil,
    })

    EMPTY_8BIT_STRING = ''
    if ::String.method_defined?(:encode)
      EMPTY_8BIT_STRING.force_encoding Encoding::ASCII_8BIT
    end

    def parse_value
      case
      when scan(STRING)
        return '' if self[1].empty?
        string = self[1].gsub(%r((?:\\[\\bfnrt"/]|(?:\\u(?:[A-Fa-f\d]{4}))+|\\[\x20-\xff]))n) do |c|
          if u = UNESCAPE_MAP[$&[1]]
            u
          else # \uXXXX
            bytes = EMPTY_8BIT_STRING.dup
            i = 0
            while c[6 * i] == ?\\ && c[6 * i + 1] == ?u
              bytes << c[6 * i + 2, 2].to_i(16) << c[6 * i + 4, 2].to_i(16)
              i += 1
            end
            JSON.iconv('utf-8', 'utf-16be', bytes)
          end
        end
        if string.respond_to?(:force_encoding)
          string.force_encoding(::Encoding::UTF_8)
        end
        string
      when scan(FLOAT)
        Float(self[1])
      when scan(INTEGER)
        Integer(self[1])
      when scan(TRUE)
        true
      when scan(FALSE)
        false
      when scan(NULL)
        nil
      #when (string = parse_string) != UNPARSED
      #  string
      when scan(ARRAY_OPEN)
        @current_nesting += 1
        ary = parse_array
        @current_nesting -= 1
        ary
      when scan(HASH_OPEN)
        @current_nesting += 1
        obj = parse_hash
        @current_nesting -= 1
        obj
      when scan(ENTITY)
        Gene::Entity.new(self[1])
      else
        UNPARSED
      end
    end

    def parse_array
      result = Array.new
      result << '[]'
      until eos?
        case
        when (value = parse_value) != UNPARSED
          result << value
        when scan(ARRAY_CLOSE)
          break
        when skip(IGNORE)
          ;
        else
          raise ParserError, "unexpected token in array at '#{peek(20)}'!"
        end
      end
      result
    end

    def parse_hash
      result = Array.new
      result << '{}'
      until eos?
        case
        when (value = parse_value) != UNPARSED
          result << value
        when scan(HASH_CLOSE)
          break
        when skip(IGNORE)
          ;
        else
          raise ParserError, "unexpected token in object at '#{peek(20)}'!"
        end
      end
      result
    end
  end
end
