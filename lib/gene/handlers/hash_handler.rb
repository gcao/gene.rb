module Gene
  module Handlers
    class HashHandler
      HASH = Gene::Types::Ident.new('{}')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first == HASH

        @logger.debug('call', group)

        Hash[*group.rest.reduce([]){|result, pair| result << pair.first << pair.second }]
      end
    end
  end
end
