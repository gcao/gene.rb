module Gene
  module Handlers
    class ArrayHandler < Gene::Handlers::Base
      def initialize(interpreter)
        super interpreter
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return Gene::NOT_HANDLED unless group.first.is_a? Gene::Types::Ident and group.first == Gene::ARRAY

        result = []
        group.rest.each do |child|
          next if child == Gene::NOOP

          value = interpreter.handle_partial(child)
          result << value if value != Gene::NOOP
        end
        result
      end
    end
  end
end
