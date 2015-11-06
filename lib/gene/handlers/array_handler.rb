module Gene
  module Handlers
    class ArrayHandler < Base
      def initialize(interpreter)
        super interpreter
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return NOT_HANDLED unless group.first.is_a? Entity and group.first == Gene::ARRAY

        result = []
        group.rest.each do |child| 
          next if child == NOOP

          value = interpreter.handle_partial(child)
          result << value if value != NOOP
        end
        result
      end
    end
  end
end
