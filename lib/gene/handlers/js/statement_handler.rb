module Gene
  module Handlers
    module Js
      class StatementHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base

          @logger.debug('call', data)

          "#{data.first}(#{data.rest.join(', ')});\n"
        end
      end
    end
  end
end

