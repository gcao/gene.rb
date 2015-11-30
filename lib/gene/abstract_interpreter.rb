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
      @handlers = Gene::Handlers::ComboHandler.new
    end

    def parent
      @stack.last
    end

    def process data
      result = nil

      if data.is_a? Stream
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
      @logger.debug('handle_partial', data.inspect)

      if data.is_a? Gene::Types::Group
        handle_group data
      elsif data.is_a? Gene::Types::Ref
        @references[data.name]
      else
        data
      end
    end

    private

    def handle_group group
      @logger.debug('handle_group', group.inspect)

      return NOOP if group == NOOP

      result = @handlers.call self, group
      if result == NOT_HANDLED
        group
      else
        handle_partial result
      end
    end
  end
end

