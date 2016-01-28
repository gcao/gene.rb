module Gene
  module Handlers
    class SetHandler
      SET = Gene::Types::Ident.new('#SET#')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group and data.first == SET

        @logger.debug('call', data)

        Set.new data.rest
      end
    end
  end
end