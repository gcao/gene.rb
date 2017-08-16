require 'strscan'

module Gene
  class Parser < StringScanner
    SEPARATOR             = /[\s()\[\]{},;]/
    SEP_OR_END            = /(?=#{SEPARATOR}|$)/
    STRING                = /"((?:[^\x0-\x1f"\\] |
                              # escaped special characters:
                              \\["\\\/bfnrt] |
                              \\u[0-9a-fA-F]{4} |
                              # match all but escaped special characters:
                              \\[\x20-\x21\x23-\x2e\x30-\x5b\x5d-\x61\x63-\x65\x67-\x6d\x6f-\x71\x73\x75-\xff])*)
                            "/nx
    SINGLE_QUOTED_STRING  = /'((?:[^\x0-\x1f'\\] |
                              # escaped special characters:
                              \\['\\\/bfnrt] |
                              \\u[0-9a-fA-F]{4} |
                              # match all but escaped special characters:
                              \\[\x20-\x21\x23-\x2e\x30-\x5b\x5d-\x61\x63-\x65\x67-\x6d\x6f-\x71\x73\x75-\xff])*)
                            '/nx
    INTEGER               = /(-?0|-?[1-9]\d*)#{SEP_OR_END}/
    FLOAT                 = /(-?
                              (?:0|[1-9]\d*)
                              (?:
                                \.\d+(?i:e[+-]?\d+) |
                                \.\d+ |
                                (?i:e[+-]?\d+)
                              )
                            )/x
    IDENT                 = /([^,\s\(\)\[\]\{\}]+)/
    # REF                   = /#(?=[a-z])/
    COMMENT               = /#<(?=[,\s\(\)\[\]\{\}]|$)/
    COMMENT_END           = />#(?=[,\s\(\)\[\]\{\}]|$)/
    COMMENT_NEXT          = /##(?=[,\s\(\)\[\]\{\}]|$)/
    GROUP_OPEN            = /\(/
    GROUP_CLOSE           = /\)/
    HASH_OPEN             = /\{/
    HASH_CLOSE            = /\}/
    ATTRIBUTE             = /\^(?=[+\-]?)/
    PAIR_DELIMITER        = /:/
    COMMA                 = /,/
    ARRAY_OPEN            = /\[/
    ARRAY_CLOSE           = /\]/
    ESCAPE                = /\\/
    TRUE                  = /true#{SEP_OR_END}/
    FALSE                 = /false#{SEP_OR_END}/
    NULL                  = /null#{SEP_OR_END}/
    UNDEFINED             = /undefined#{SEP_OR_END}/
    PLACEHOLDER           = /#_#{SEP_OR_END}/
    IGNORE                = %r(
      (?:
       \#([,\s\(\)\{\}\[\]]+[^\n\r]*([\n\r]|$))| # line comments
       [\s]+             # whitespaces: space, horicontal tab, lf, cr
      )+
    )mx

    UNPARSED  = Object.new
    IGNORABLE = Object.new

    def self.parse input, options = {}
      new(input, options).parse
    end

    def initialize(source, options = {})
      @logger = Logem::Logger.new self
      @logger.debug('initialize', source, options)
      @options = options
      super source
    end

    def parse
      @logger.debug 'parse'
      reset

      obj = UNPARSED

      until eos?
        case
        when skip(IGNORE)
          ;
        when (value = parse_string) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_float) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_int) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_keywords) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_placeholder) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_group) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_hash) != UNPARSED
          obj = handle_top_level_results obj, value
        # when (value = parse_ref) != UNPARSED
        #   obj = handle_top_level_results obj, value
        when (value = parse_attribute) != UNPARSED
          obj = handle_top_level_results obj, value
        when (value = parse_ident) != UNPARSED
          obj = handle_top_level_results obj, value
        else
          raise ParseError, "source '#{peek(20)}' is not valid GENE!"
        end
      end

      if obj == UNPARSED
        Gene::Types::Stream.new
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
      elsif container.is_a? Gene::Types::Stream
        container << new_result
      else
        Gene::Types::Stream.new(container, new_result)
      end
    end

    def parse_value
      skip(IGNORE)

      case
      when (value = parse_string) != UNPARSED
        value
      when (value = parse_float) != UNPARSED
        value
      when (value = parse_int) != UNPARSED
        value
      when (value = parse_keywords) != UNPARSED
        value
      when (value = parse_comment_next) != UNPARSED
        value
      when (value = parse_placeholder) != UNPARSED
        value
      when (value = parse_group) != UNPARSED
        value
      when (value = parse_hash) != UNPARSED
        value
      # when (value = parse_ref) != UNPARSED
      #   value
      when (value = parse_attribute) != UNPARSED
        value
      when (value = parse_ident) != UNPARSED
        value
      else
        UNPARSED
      end
    end

    def parse_string
      return UNPARSED unless scan(STRING) || scan(SINGLE_QUOTED_STRING)

      return '' if self[1].empty?
      string = self[1].gsub(%r((?:\\[\\bfnrt"'/]|(?:\\u(?:[A-Fa-f\d]{4}))+|\\[\x20-\xff]))n) do |c|
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

    def parse_keywords
      if scan(NULL)
        return nil
      elsif scan(TRUE)
        return true
      elsif scan(FALSE)
        return false
      elsif scan(UNDEFINED)
        return Gene::UNDEFINED
      else
        return UNPARSED
      end
    end

    def parse_comment_next
      return UNPARSED unless scan(COMMENT_NEXT)

      Gene::COMMENT_NEXT
    end

    def parse_placeholder
      return UNPARSED unless scan(PLACEHOLDER)

      Gene::PLACEHOLDER
    end

    def parse_ident
      return UNPARSED unless check(IDENT)

      escaped = !!check(ESCAPE)
      value = ''

      until eos?
        case
        when check(SEPARATOR)
          break
        when scan(ESCAPE)
          value += getch
        else
          value += getch
        end
      end

      Gene::Types::Ident.new(value, escaped)
    end

    # def parse_ref
    #   return UNPARSED unless scan(REF)

    #   value = ''

    #   until eos?
    #     case
    #     when check(SEPARATOR)
    #       break
    #     when scan(ESCAPE)
    #       value += getch
    #     else
    #       value += getch
    #     end
    #   end

    #   Gene::Types::Ref.new(value)
    # end

    def parse_attribute
      return UNPARSED unless scan(ATTRIBUTE)

      value = ''

      until eos?
        case
        when check(SEPARATOR)
          break
        when scan(ESCAPE)
          value += getch
        else
          value += getch
        end
      end

      if value =~ /^[\^\!\+\-]?(.*)^?$/
        key = $1
        if value[0] == '+' or value[0] == '^'
          @attribute_for_group[key] = true
        elsif value[0] == '-' or value[0] == '!'
          @attribute_for_group[key] = false
        else
          next_value = parse_value
          if next_value == UNPARSED
            raise ParseError, "Attribute for \"#{key}\" is not found"
          end

          @attribute_for_group[key] = next_value
        end
        IGNORABLE
      else
        raise "Should never reach here"
      end
    end

    def parse_group
      return UNPARSED unless scan(GROUP_OPEN) || scan(ARRAY_OPEN)

      @attribute_for_group = {}

      result = Array.new

      open_char = self[0]

      raise ParseError, "Incomplete content after '#{open_char}'" if eos?

      in_comment   = false
      closed       = false

      until eos?
        case
        when skip(COMMENT_END)
         in_comment = false
        when open_char == '(' && scan(GROUP_CLOSE)
          closed = true
          break
        when open_char == '[' && scan(ARRAY_CLOSE)
          closed = true
          break
        when skip(COMMENT)
         in_comment = true
        when skip(IGNORE)
          ;
        when (value = parse_value) != UNPARSED
          result << value unless in_comment or value == IGNORABLE
        else
          raise ParseError, "unexpected token at '#{peek(20)}'!"
        end
      end

      raise ParseError, "unexpected end of input" unless closed

      return result if open_char == '[' # Array

      return Gene::NOOP if result.length == 0 # NOOP

      type = result.shift
      data = result
      gene = Gene::Types::Base.new type, *data
      @attribute_for_group.each do |k, v|
        gene.attributes[k] = v
      end
      gene
    end

    def parse_hash
      return UNPARSED unless scan(HASH_OPEN)

      result = []

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
          elsif scan(COMMENT_NEXT)
            raise ParseError, "unexpected token at '#{peek(20)}'!"
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
          elsif scan(COMMENT_NEXT)
            raise ParseError, "unexpected token at '#{peek(20)}'!"
          elsif (parsed = parse_value) == UNPARSED
            raise ParseError, "unexpected token at '#{peek(20)}'!"
          else
            value = parsed
            result << [key, value]
          end
        else

        end
        expect_index += 1
      end

      result.reduce({}) do |hash, pair|
        hash[pair[0]] = pair[1]
        hash
      end
    end
  end
end
