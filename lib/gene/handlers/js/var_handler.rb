module Gene
  module Handlers
    module Js
      class VarHandler
        VAR = Gene::Types::Ident.new('var')

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          @logger.debug('call', group)

          return Gene::NOT_HANDLED unless group.first == VAR

          group.join(' ') + ";\n"
        end
      end
    end
  end
end

