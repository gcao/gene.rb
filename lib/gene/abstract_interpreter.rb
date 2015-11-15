module Gene
  class AbstractInterpreter
    attr :logger
    attr :handlers
    attr :stack
    attr :references

    def initialize
      @logger = Logem::Logger.new(self)
      @stack = []
      @references = {}
    end

    def parent
      @stack.last
    end

    def process data
      result = nil

      #if data.is_a? Stream
      #  data.each do |item|
      #    result = handle_partial item
      #    result = yield result if block_given?
      #  end
      #else
        result = handle_partial data
        result = yield result if block_given?
      #end

      result
    end

    def handle_partial data
      @logger.debug('handle_partial', data.inspect)

      #normalize data

      if data.is_a? Gene::Types::Group
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
        result = handler.call self, group
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

    #def normalize group_or_array
    #  case group_or_array
    #  when Gene::Types::Group
    #    group_or_array.reject!{|child| child == NOOP }
    #  when Array
    #    group_or_array.reject!{|item| item == NOOP }
    #  end

    #  group_or_array
    #end
  end
end

