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

          fn_name = group.shift.name
          args = group.shift || []

<<-JS
function #{fn_name}(#{args.join(', ')}){
#{group.join("\n")}
}
JS
        end
      end
    end
  end
end

