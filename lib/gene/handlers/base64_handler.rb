module Gene
  module Handlers
    class Base64Handler < Base
      BASE64 = Gene::Types::Ident.new('base64')

      def initialize(interpreter)
        super interpreter
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return Gene::NOT_HANDLED unless group.first == BASE64

        Gene::Types::Base64.new group[1]
      end
    end
  end
end
