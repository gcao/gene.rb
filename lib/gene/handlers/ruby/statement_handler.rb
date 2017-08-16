module Gene
  module Handlers
    module Ruby
      class StatementHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          @logger.debug('call', data)

          if data.is_a? Gene::Types::Base
            "#{data.type}(#{data.data.join(', ')})"
          else
            data
          end
        end
      end
    end
  end
end

