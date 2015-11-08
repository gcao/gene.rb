module Gene
  module Handlers
    class ArrayHandler
      ARRAY = Gene::Types::Ident.new('[]')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first == ARRAY

        @logger.debug('call', group)

        result = []
        group.rest.each do |child|
          next if child == Gene::NOOP

          value = context.handle_partial(child)
          result << value if value != Gene::NOOP
        end
        result
      end
    end
  end
end
