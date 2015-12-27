module Gene
  module Handlers
    class HashHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Hash

        @logger.debug('call', data)

        result = {}
        data.each do |k, v|
          key = context.handle_partial(k)
          result[key] = context.handle_partial(v) if key != Gene::NOOP
        end
        result
      end
    end
  end
end
