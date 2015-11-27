module Gene
  module Handlers
    module Js
      class ReturnHandler
        RETURN = Gene::Types::Ident.new('return')

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          @logger.debug('call', group)

          return Gene::NOT_HANDLED unless group.first == RETURN

          group.join(' ') + ";\n"
        end
      end
    end
  end
end

