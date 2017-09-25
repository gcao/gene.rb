module Gene
  module Handlers
    module Js
      class ReturnHandler
        RETURN = Gene::Types::Symbol.new('return')

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == RETURN

          @logger.debug('call', data)

          data.type.to_s + ' ' + data.data.join(' ') + ";\n"
        end
      end
    end
  end
end

