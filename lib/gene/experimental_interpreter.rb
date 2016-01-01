module Gene
  class ExperimentalInterpreter < AbstractInterpreter
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
      super

      @handlers =
        self.class.handlers
          .sort {|h1, h2| h2[:priority] <=> h1[:priority] }
          .map  {|option| method(option[:method]) }
    end

    # Override method in base class to not pass context (the interpreter itself can act as the context)
    def handle_partial data
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
      return NOT_HANDLED unless data.is_a? Fixnum

      data
    end

    handler
    def handle_plus data
      return Gene::NOT_HANDLED unless data[1].is_a? Gene::Types::Ident and data[1].name == '+'

      handle_partial(data[0]) + handle_partial(data[2])
    end

    handler priority: HIGH
    def handle_multiply data
      return NOT_HANDLED unless data.is_a? Gene::Types::Group

      index =  data.index {|item| item.is_a? Gene::Types::Ident and item.name == '*' }

      if index.nil?
        return NOT_HANDLED
      elsif index == 0
        raise 'Invalid expression: left hand part of multiplication is not found'
      elsif index == data.length - 1
        raise 'Invalid expression: right hand part of multiplication is not found'
      else
        # TODO
      end
    end

  end
end

