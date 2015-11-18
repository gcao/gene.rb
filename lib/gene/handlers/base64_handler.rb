module Gene
  module Handlers
    class Base64Handler
      BASE64 = Gene::Types::Ident.new('#base64')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first == BASE64

        @logger.debug('call', group)

        Gene::Types::Base64.new group[1]
      end
    end
  end
end
