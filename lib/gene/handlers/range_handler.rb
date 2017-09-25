module Gene
  module Handlers
    class RangeHandler
      RANGE = Gene::Types::Symbol.new('#..')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == RANGE

        @logger.debug('call', data)

        Range.new(*data.data)
      end
    end
  end
end
