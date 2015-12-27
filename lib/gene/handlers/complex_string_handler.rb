module Gene
  module Handlers
    class ComplexStringHandler
      COMPLEX_STRING1 = Gene::Types::Ident.new('#""')
      COMPLEX_STRING2 = Gene::Types::Ident.new("#''")

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        unless data.is_a? Gene::Types::Group and 
               (data.first == COMPLEX_STRING1 or data.first == COMPLEX_STRING2)
          return Gene::NOT_HANDLED
        end

        @logger.debug('call', data)

        Gene::Types::ComplexString.new *data.rest
      end
    end
  end
end
