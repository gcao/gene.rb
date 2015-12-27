module Gene
  module Handlers
    class ArrayHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Array and not data.is_a? Gene::Types::Group

        @logger.debug('call', data)

        result = []
        data.each do |child|
          next if child == Gene::NOOP

          value = context.handle_partial(child)
          result << value if value != Gene::NOOP
        end
        result
      end
    end
  end
end
