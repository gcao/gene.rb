require 'strscan'

# This is copied and modified from the pure Ruby JSON parser that can be found on below page
# https://github.com/flori/json/blob/master/lib/json/pure/parser.rb
module Gene
  class Parser < StringScanner
    SEPARATOR             = /[\s()\[\]{},;]/
    SEP_OR_END            = /(?=#{SEPARATOR}|$)/
    STRING                = /"((?:[^\x0-\x1f"\\] |
                              [\n\r\t] |
                              # escaped special characters:
                              \\["\\\/bfnrt] |
                              \\u[0-9a-fA-F]{4} |
                              # match all but escaped special characters:
                              \\[\x20-\x21\x23-\x2e\x30-\x5b\x5d-\x61\x63-\x65\x67-\x6d\x6f-\x71\x73\x75-\xff])*)
                            "/nx
    SINGLE_QUOTED_STRING  = /'((?:[^\x0-\x1f'\\] |
                              [\n\r\t] |
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
    SYMBOL                 = /([^"',\s\(\)\[\]\{\}][^,\s\(\)\[\]\{\}]*)/
    REGEXP                 = /#\/(([^\/]+|(\\.)+)*)\/([a-z]*)/
    # REF                   = /#(?=[a-z])/
    COMMENT               = /#<(?=[,\s\(\)\[\]\{\}]|$)/
    COMMENT_END           = />#(?=[,\s\(\)\[\]\{\}]|$)/

    QUOTE                 = /`/
    QUOTE_SYMBOL          = Gene::Types::Symbol.new('#QUOTE')

    GROUP_OPEN            = /\(/
    GROUP_CLOSE           = /\)/
    HASH_OPEN             = /\{/
    HASH_CLOSE            = /\}/
    ATTRIBUTE             = /\^(?=[+\-]?)/
    COMMA                 = /,/
    ARRAY_OPEN            = /\[/
    ARRAY_CLOSE           = /\]/
    ESCAPE                = /\\/
    TRUE                  = /true#{SEP_OR_END}/
    FALSE                 = /false#{SEP_OR_END}/
    NULL                  = /null#{SEP_OR_END}/
    UNDEFINED             = /undefined|void#{SEP_OR_END}/
    PLACEHOLDER           = /#_#{SEP_OR_END}/
    IGNORE                = %r(
      (?:
       \#($ | \r?\n | \s+[^\n\r]*($|\r?\n) | ![^\n\r]*($|\r?\n))|   # line comments
       [\s,]+             # whitespaces: space, horicontal tab, lf, cr
      )+
    )mx

    UNPARSED  = Object.new
    IGNORABLE = Object.new

    RANGE = Gene::Types::Symbol.new('#..')
    SET   = Gene::Types::Symbol.new('#<>')
    END_SYMBOL = Gene::Types::Symbol.new('#END')

    STREAM_TYPE = Gene::Types::Symbol.new('#STREAM')

    ENV_TYPE = Gene::Types::Symbol.new('#ENV')

    GENE_PI = Gene::Types::Symbol.new('#GENE')

    # Document level instructions
    DOCUMENT_INSTRUCTIONS = %w(version)

    DEFAULT_DOCUMENT_VERSION = "1.0"

    # TODO: we can potentially add below
    # Group instructions
    # Array instructions
    # Hash  instructions

    attr_accessor :version

    def self.parse input, options = {}
      new(input, options).parse
    end

    def initialize(source, options = {})
      @logger = Logem::Logger.new self
      @logger.debug('initialize', source, options)
      @options = options
      super source
    end

    def version
      @version || DEFAULT_DOCUMENT_VERSION
    end

    def env
      @options['env'] || ENV
    end

    def parse
      @logger.debug 'parse'
      reset

      result = Gene::Types::Stream.new

      until eos?
        case
        when skip_whitespace_or_comments
          ;
        when (value = parse_quote) != UNPARSED
          result << value
        when (value = parse_string) != UNPARSED
          result << value
        when (value = parse_float) != UNPARSED
          result << value
        when (value = parse_int) != UNPARSED
          result << value
        when (value = parse_keywords) != UNPARSED
          result << value
        when (value = parse_placeholder) != UNPARSED
          result << value
        when (value = parse_group) != UNPARSED
          if value != IGNORABLE
            result << value
          end
        when (value = parse_hash) != UNPARSED
          result << value
        # when (value = parse_ref) != UNPARSED
        #   result << value
        # Attribute should not appear on top level
        # when (value = parse_attribute) != UNPARSED
        #   result << value
        when (value = parse_regexp) != UNPARSED
          result << value
        when (value = parse_symbol) != UNPARSED
          if value == END_SYMBOL
            break
          end
          result << value
        else
          if %w(' ").include? peek(1)
            raise PrematureEndError, "Incomplete content"
          else
            raise ParseError, "source '#{peek(20)}' is not valid GENE!"
          end
        end
      end

      if result.size == 1
        result[0]
      else
        result
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

    def parse_value options = {}
      skip_whitespace_or_comments

      case
      when (value = parse_quote) != UNPARSED
        value
      when (value = parse_string) != UNPARSED
        value
      when (value = parse_float) != UNPARSED
        value
      when (value = parse_int) != UNPARSED
        value
      when (value = parse_keywords) != UNPARSED
        value
      when (value = parse_placeholder) != UNPARSED
        value
      when (value = parse_group) != UNPARSED
        value
      when (value = parse_hash) != UNPARSED
        value
      # when (value = parse_ref) != UNPARSED
      #   value
      when options[:attributes] && (value = parse_attribute(options[:attributes])) != UNPARSED
        value
      when (value = parse_regexp) != UNPARSED
        value
      when (value = parse_symbol) != UNPARSED
        if value == END_SYMBOL
          raise ParseError, '#END is only allowed on the top level!'
        end
        value
      when eos?
        raise PrematureEndError, "Incomplete content"
      else
        if %w(' ").include? peek(1)
          raise PrematureEndError, "Incomplete content"
        else
          raise ParseError, "unexpected token at '#{peek(20)}'!"
        end
      end
    end

    def skip_whitespace_or_comments
      did_skip = false

      loop do
        did_skip ||= skip(IGNORE)

        if skip(COMMENT)
          did_skip = true
          until eos?
            if skip(COMMENT_END)
              break
            else
              # Get next char and discard
              getch
            end
          end
        else
          break
        end
      end

      did_skip
    end

    def parse_quote
      if scan(QUOTE)
        return Gene::Types::Base.new(QUOTE_SYMBOL, parse_value)
      else
        return UNPARSED
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

    def parse_placeholder
      return UNPARSED unless scan(PLACEHOLDER)

      Gene::PLACEHOLDER
    end

    def parse_symbol
      return UNPARSED unless check(SYMBOL)

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

      Gene::Types::Symbol.new(value, escaped)
    end

    def parse_regexp
      return UNPARSED unless scan(REGEXP)

      value = self[1]
      flags = self[4]
      options = 0

      if flags.include?('i')
        options |= Regexp::IGNORECASE
      end
      if flags.include?('m')
        options |= Regexp::MULTILINE
      end
      if flags.include?('x')
        options |= Regexp::EXTENDED
      end

      Regexp.new(value, options)
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

    def parse_attribute attribute_for_group
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
          attribute_for_group[key] = true
        elsif value[0] == '-' or value[0] == '!'
          attribute_for_group[key] = false
        else
          next_value = parse_value
          if next_value == UNPARSED
            raise ParseError, "Attribute for \"#{key}\" is not found"
          end

          attribute_for_group[key] = next_value
        end
        IGNORABLE
      else
        raise "Should never reach here"
      end
    end

    def parse_group
      return UNPARSED unless scan(GROUP_OPEN) || scan(ARRAY_OPEN)

      attribute_for_group = {}

      result = Array.new

      open_char = self[0]

      while true
        skip_whitespace_or_comments

        case
        when open_char == '(' && scan(GROUP_CLOSE)
          break
        when open_char == '[' && scan(ARRAY_CLOSE)
          break
        when open_char == '(' && (value = parse_value(attributes: attribute_for_group)) != UNPARSED
          result << value unless value == IGNORABLE
        when open_char == '[' && (value = parse_value) != UNPARSED
          result << value unless value == IGNORABLE
        when eos?
          raise PrematureEndError, "unexpected end of input"
        else
          raise ParseError, "unexpected token at '#{peek(20)}'!"
        end
      end

      return result if open_char == '[' # Array

      return Gene::NOOP if result.length == 0 # NOOP

      type = result.shift
      data = result

      if type == RANGE
        return Range.new data[0], data[1]
      elsif type == SET
        return Set.new data
      end

      gene = Gene::Types::Base.new type, *data
      attribute_for_group.each do |k, v|
        gene.properties[k] = v
      end

      if type == GENE_PI
        handle_processing_instructions gene
      elsif type == ENV_TYPE
        handle_env gene
      elsif type == STREAM_TYPE
        handle_stream gene
      else
        gene
      end
    end

    def parse_hash
      return UNPARSED unless scan(HASH_OPEN)

      result = {}
      closed = false

      until eos?
        skip_whitespace_or_comments

        if scan(HASH_CLOSE)
          closed = true
          break
        elsif (parsed = parse_attribute(result)) != UNPARSED
          next
        else
          raise ParseError, "unexpected token at '#{peek(20)}'!"
        end
      end

      raise PrematureEndError, "Incomplete content" unless closed

      result
    end

    def handle_processing_instructions gene
      gene.properties.each do |key, value|
        if DOCUMENT_INSTRUCTIONS.include?(key)
          send "#{key}=", value
        end
      end
      result = Gene::UNDEFINED
      gene.data.each do |item|
        if DOCUMENT_INSTRUCTIONS.include?(item.to_s)
          result = send item.to_s
        end
      end
      if result == Gene::UNDEFINED
        IGNORABLE
      else
        result
      end
    end

    def handle_env gene
      env[gene.data.first.to_s]
    end

    def handle_stream gene
      Gene::Types::Stream.new *gene.data
    end
  end
end
