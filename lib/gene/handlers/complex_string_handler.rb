module Gene
  module Handlers
    class ComplexStringHandler
      COMPLEX_STRING1 = Gene::Types::Ident.new('#""')
      COMPLEX_STRING2 = Gene::Types::Ident.new("#''")

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first == COMPLEX_STRING1 or
                                        group.first == COMPLEX_STRING2

        @logger.debug('call', group)

        Gene::Types::ComplexString.new *group.rest
      end
    end
  end
end
