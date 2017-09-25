module Gene
  module Handlers
    class Base64Handler
      BASE64 = Gene::Types::Symbol.new('#BASE64')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == BASE64

        @logger.debug('call', data)

        Gene::Types::Base64.new data.data[0]
      end
    end
  end
end
