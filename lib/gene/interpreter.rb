module Gene
  class Interpreter
    attr :context
    attr :logger

    def initialize
      @logger = Logem::Logger.new(self)
      @context = Context.new(self)
    end

    def handlers= value
      @handlers = value
    end

    def run data
      if data.is_a? Stream
        # TODO create an enumerator
        result = nil
        data.each do |item|
          result = handle_partial item
        end
        result
      else
        handle_partial data
      end
    end

    def handle_partial data
      @logger.debug('handle_partial', data.inspect)

      self.class.normalize data

      if data.is_a? Group
        handle_group data
      else
        data
      end
    end

    private

    def handle_group group
      @logger.debug('handle_group', group.inspect)

      return NOOP if group == NOOP

      handled = false
      result = @handlers.each do |handler|
        result = handler.call group
        next if result == NOT_HANDLED

        handled = true
        break handle_partial(result)
      end

      if handled
        result
      else
        group
      end
    end

    def self.normalize group_or_array
      case group_or_array
      when Group
        group_or_array.reject!{|child| child == NOOP }
      when Array
        group_or_array.reject!{|item| item == NOOP }
      end

      group_or_array
    end
  end
end

