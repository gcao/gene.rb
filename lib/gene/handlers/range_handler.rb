module Gene
  module Handlers
    class RangeHandler < Base
      RANGE = Gene::Types::Ident.new('..')

      def initialize(interpreter)
        super interpreter
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return Gene::NOT_HANDLED unless group.first == RANGE

        Range.new(*group.rest)
      end
    end
  end
end
