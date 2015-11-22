module Gene
  module Handlers
    module Js
      class FunctionHandler
        FUNCTION = Gene::Types::Ident.new 'function'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED unless group.first == FUNCTION

          @logger.debug('call', group)

          group.shift

          class_name = group.shift.name

<<-JS
function #{class_name}(){
}; #{class_name};
JS
        end
      end
    end
  end
end

