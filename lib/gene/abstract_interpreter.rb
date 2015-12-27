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
      #@logger.debug('handle_partial', data.inspect)

      result = @handlers.call self, data
      if result == NOT_HANDLED
        data
      else
        result
      end
    end
  end
end

