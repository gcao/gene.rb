module Gene
  module Handlers
    class TestHandler < Base
      LET = Entity.new('let')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return NOT_HANDLED unless group.first.is_a? Entity and group.first.name == '$$'

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
