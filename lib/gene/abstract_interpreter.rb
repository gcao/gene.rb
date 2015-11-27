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
      @handlers = [
        Gene::Handlers::ArrayHandler.new,
        Gene::Handlers::HashHandler.new,
        Gene::Handlers::ComplexStringHandler.new,
        Gene::Handlers::RangeHandler.new,
        Gene::Handlers::Base64Handler.new,
        Gene::Handlers::RegexpHandler.new,
        Gene::Handlers::RefHandler.new,
      ]
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
  end
end

