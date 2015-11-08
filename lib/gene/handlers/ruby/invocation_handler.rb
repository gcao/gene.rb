module Gene
  module Handlers
    module Ruby
      class InvocationHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED unless group.first.name =~ /^\./

          @logger.debug('call', group)

          "self#{group.first}(#{group.rest.map(&:inspect).join(', ')})"
        end
      end
    end
  end
end

