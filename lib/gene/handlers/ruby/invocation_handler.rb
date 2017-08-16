module Gene
  module Handlers
    module Ruby
      class InvocationHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.first.name =~ /^\./

          @logger.debug('call', data)

          "self#{data.first}(#{data.rest.map(&:inspect).join(', ')})"
        end
      end
    end
  end
end

