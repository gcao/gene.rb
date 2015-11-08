module Gene
  module Handlers
    class TestHandler
      LET = Gene::Types::Ident.new('let')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first.is_a? Gene::Types::Ident and group.first.name == '$$'

        @logger.debug('call', group)

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
