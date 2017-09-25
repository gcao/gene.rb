module Gene
  module Handlers
    class TupleHandler
      TUPLE = Gene::Types::Symbol.new('#||')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless TUPLE === data

        @logger.debug('call', data)

        Gene::Types::Tuple.new(*data.data)
      end
    end
  end
end
