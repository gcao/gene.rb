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
        group.to_s
        #NOT_HANDLED
      end
    end
  end
end

