module Gene
  module Handlers
    class ComplexStringHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first == ""

        @logger.debug('call', group)

        Gene::Types::ComplexString.new *group.rest
      end
    end
  end
end
