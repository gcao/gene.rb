module Gene
  module Handlers
    class Base
      attr :context

      def initialize context
        @logger = Logem::Logger.new(self)
        @context = context
      end

      def call group
        @logger.debug('call', group)
        NOT_HANDLED
      end
    end
  end
end

