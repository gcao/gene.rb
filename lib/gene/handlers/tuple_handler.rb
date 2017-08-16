module Gene
  module Handlers
    class TupleHandler
      TUPLE = Gene::Types::Ident.new('#||')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless TUPLE.first_of_group? data

        @logger.debug('call', data)

        Gene::Types::Tuple.new(*data.data)
      end
    end
  end
end
