module Gene
  module Handlers
    class RangeHandler < Base
      def initialize(interpreter)
        super interpreter
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return Gene::NOT_HANDLED unless group.first.is_a? Gene::Types::Ident and group.first == Gene::RANGE

        Range.new(*group.rest)
      end
    end
  end
end
