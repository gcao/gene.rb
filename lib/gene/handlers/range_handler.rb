module Gene
  module Handlers
    class RangeHandler
      RANGE = Gene::Types::Ident.new('#..')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group and data.first == RANGE

        @logger.debug('call', data)

        Range.new(*data.rest)
      end
    end
  end
end
