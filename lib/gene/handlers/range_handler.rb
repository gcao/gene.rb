module Gene
  module Handlers
    class RangeHandler
      RANGE = Gene::Types::Ident.new('..')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first == RANGE

        @logger.debug('call', group)

        Range.new(*group.rest)
      end
    end
  end
end
