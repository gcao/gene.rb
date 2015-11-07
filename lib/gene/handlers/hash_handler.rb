module Gene
  module Handlers
    class HashHandler < Base
      def initialize(interpreter)
        super interpreter
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return Gene::NOT_HANDLED unless group.first.is_a? Gene::Types::Ident and group.first == Gene::HASH

        Hash[*group.rest.reduce([]){|result, pair| result << pair.first << pair.second }]
      end
    end
  end
end
