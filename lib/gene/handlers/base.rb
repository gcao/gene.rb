module Gene
  module Handlers
    class Base
      attr :interpreter

      def initialize interpreter
        @logger = Logem::Logger.new(self)
        @interpreter = interpreter
      end

      def call group
        @logger.debug('call', group)
        if group.is_a? Group
          "(#{group.map{|item| @interpreter.handle_partial(item)}.join(' ')});"
        else
          group
        end
        #NOT_HANDLED
      end
    end
  end
end

