module Gene
  module Handlers
    class TestHandler < Base
      LET = Gene::Types::Ident.new('let')

      def initialize(interpreter)
        super interpreter
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return Gene::NOT_HANDLED unless group.first.is_a? Gene::Types::Ident and group.first.name == '$$'

        group.shift

        case group.first
        when LET

        else
          group
        end
      end
    end
  end
end
