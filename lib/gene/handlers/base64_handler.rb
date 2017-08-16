module Gene
  module Handlers
    class Base64Handler
      BASE64 = Gene::Types::Ident.new('#BASE64')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.first == BASE64

        @logger.debug('call', data)

        Gene::Types::Base64.new data[1]
      end
    end
  end
end
