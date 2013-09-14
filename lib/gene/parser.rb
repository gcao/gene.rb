require 'strscan'

module Gene
  class Parser < StringScanner
    STRING                = /"((?:[^\x0-\x1f"\\] |
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
    ENTITY                = /([^,\s\(\)\[\]\{\}]+)/
    ENTITY_END            = /[,\s\(\)\[\]\{\}]/
    GENE_OPEN             = /\(/
    GENE_CLOSE            = /\)/
    HASH_OPEN             = /\{/
    HASH_CLOSE            = /\}/
    PAIR_DELIMITER        = /:/
    COMMA                 = /,/
    ARRAY_OPEN            = /\[/
    ARRAY_CLOSE           = /\]/
    ESCAPE                = /\\/
    TRUE                  = /true/
    FALSE                 = /false/
    NULL                  = /null/
    IGNORE                = %r(
      (?:
       \#[^\n\r]*[\n\r]| # line comments
       [\s]+             # whitespaces: space, horicontal tab, lf, cr
      )+
    )mx

    UNPARSED = Object.new

    def initialize(source, options = {})
      @logger = Logem::Logger.new self
      @logger.debug('initialize', source, options)
      @options = options
      super source
    end

    #alias source string

    def parse
      @logger.debug 'parse'
      reset

      obj = UNPARSED

      until eos?
        case
        when (value = parse_string) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_float) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_int) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_true) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_false) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_null) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_group) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_hash) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_entity) != UNPARSED
          obj = handle_top_level_results obj, value
        when skip(IGNORE)
          ;
        else
          raise ParseError, "source '#{peek(20)}' is not valid GENE!"
        end
      end

      if obj == UNPARSED
        Gene::Stream.new
      else
        obj
      end
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

    def handle_top_level_results container, new_result
      if container == UNPARSED
        new_result
      elsif container.is_a? Stream
        container << new_result
      else
        Stream.new(container, new_result)
      end
    end

    def parse_value
      case
      when (value = parse_string) != UNPARSED
        value
      when (value = parse_float ) != UNPARSED
        value
      when (value = parse_int   ) != UNPARSED
        value
      when (value = parse_true  ) != UNPARSED
        value
      when (value = parse_false ) != UNPARSED
        value
      when (value = parse_null  ) != UNPARSED
        value
      when (value = parse_group ) != UNPARSED
        value
      when (value = parse_hash ) != UNPARSED
        value
      when (value = parse_entity) != UNPARSED
        value
      else
        UNPARSED
      end
    end

    def parse_string
      return UNPARSED unless scan(STRING)

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
    end

    def parse_int
      return UNPARSED unless scan(INTEGER)

      Integer(self[1])
    end

    def parse_float
      return UNPARSED unless scan(FLOAT)

      Float(self[1])
    end

    def parse_true
      return UNPARSED unless scan(TRUE)

      true
    end

    def parse_false
      return UNPARSED unless scan(FALSE)

      false
    end

    def parse_null
      return UNPARSED unless scan(NULL)

      nil
    end

    def parse_entity
      return UNPARSED unless check(ENTITY)

      value = ''

      until eos?
        case
        when check(ENTITY_END)
          break
        when scan(ESCAPE)
          value += getch
        else
          value += getch
        end
      end

      Entity.new(value)
    end

    def parse_group
      return UNPARSED unless scan(GENE_OPEN) || scan(ARRAY_OPEN)

      result = Array.new

      open_char = self[0]
      if open_char == '[' 
        result << Entity.new('[]')
      end

      raise ParseError, "Incomplete content after '#{open_char}'" if eos?

      until eos?
        case
        when open_char == '(' && scan(GENE_CLOSE)
          break
        when open_char == '[' && scan(ARRAY_CLOSE)
          break
        when (value = parse_value) != UNPARSED
          result << value
        when skip(IGNORE)
          ;
        else
          raise ParseError, "unexpected token at '#{peek(20)}'!"
        end
      end

      Group.new(*result)
    end

    def parse_hash
      return UNPARSED unless scan(HASH_OPEN)

      result = Array.new
      result << Entity.new('{}')

      expects = %w(key delimiter value)
      expect_index = 0

      raise ParseError, "Incomplete content after '#{open_char}'" if eos?

      until eos?
        next if skip(IGNORE)

        case expects[expect_index % expects.size]
        when 'key'
          if scan(HASH_CLOSE)
            break
          elsif scan(COMMA)
            next
          elsif (parsed = parse_value) == UNPARSED
            raise ParseError, "unexpected token at '#{peek(20)}'!"
          else
            key = parsed
          end
        when 'delimiter'
          if !scan(PAIR_DELIMITER)
            raise ParseError, "unexpected token at '#{peek(20)}'!"
          end
        when 'value'
          if scan(HASH_CLOSE)
            raise ParseError, "unexpected token at '#{peek(20)}'!"
          elsif (parsed = parse_value) == UNPARSED
            raise ParseError, "unexpected token at '#{peek(20)}'!"
          else
            value = parsed
            result << Pair.new(key, value)
          end
        else

        end
        expect_index += 1
      end

      Group.new(*result)
    end
  end
end
