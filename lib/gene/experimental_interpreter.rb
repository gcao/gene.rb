module Gene
  class ExperimentalInterpreter
    LOW    = 0
    NORMAL = 100
    HIGH   = 200

    @handlers = []

    def self.handlers; @handlers; end

    def self.handler options = {}
      options[:priority] ||= NORMAL
      @handler_option = options
    end

    def self.method_added method
      return if @handler_option.nil?

      @handlers << @handler_option.merge(method: method)
      remove_instance_variable :@handler_option
    end

    def initialize
      @logger   = Logem::Logger.new(self)
      @handlers =
        self.class.handlers
          .sort {|h1, h2| h2[:priority] <=> h1[:priority] }
          .map  {|option| method(option[:method]) }
    end

    def parse_and_process input, &block
      @logger.debug('parse_and_process', input)

      CoreInterpreter.parse_and_process "(#{input})" do |output|
        process output, &block
      end
    end

    def process data
      result = nil

      if data.is_a? Gene::Types::Stream
        data.each do |item|
          result = handle_partial item
          result = yield result if block_given?
        end
      else
        result = handle_partial data
        result = yield result if block_given?
      end

      result
    end

    def handle_partial data
      @logger.debug('handle_partial', data)

      @handlers.each do |handler|
        result = handler.call data
        if result != NOT_HANDLED
          return result
        end
      end

      NOT_HANDLED
    end

    # Handlers
    handler
    def handle_literal data
      if data.is_a? Gene::Types::Base and data.length == 1
        @logger.debug('handle_literal', data)
        handle_partial(data.first)
      elsif data.is_a? Fixnum
        @logger.debug('handle_literal', data)
        data
      else
        NOT_HANDLED
      end
    end

    handler
    def handle_plus data
      return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data[1].is_a? Gene::Types::Ident and data[1].name == '+'

      @logger.debug('handle_plus', data)
      result = handle_partial(data[0]) + handle_partial(data[2])
      data[0..2] = result
      handle_partial(data)
    end

    handler priority: HIGH
    def handle_multiply data
      return NOT_HANDLED unless data.is_a? Gene::Types::Base

      index =  data.index {|item| item.is_a? Gene::Types::Ident and item.name == '*' }

      if index.nil?
        return NOT_HANDLED
      else
        @logger.debug('handle_multiply', data)
        result = handle_partial(data[index - 1]) * handle_partial(data[index + 1])
        data[index-1 .. index+1] = result
        handle_partial data
      end
    end

  end
end

