module Gene
  module Handlers
    module Js
      class FunctionHandler
        FUNCTION = Gene::Types::Ident.new 'function'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        # Supports
        # (function name [args] [body])
        # (function name [body])
        # (function [args] [body])
        # (function [body])
        # If body is composed of only one statement, [] is optional
        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.first == FUNCTION

          @logger.debug('call', data)

          data.shift

          fn_name = data.first.is_a?(Gene::Types::Ident) ? data.shift.name : ""

          args = data.shift
          #if args
          #  args = context.handle_partial(args)
          #else
          #  args = []
          #end

          body = data.shift
          if body
            if body.is_a? Array
              body = body.map {|stmt| context.handle_partial(stmt) }
            else
              body = [context.handle_partial(body)]
            end
          else
            body = []
          end

<<-JS
function #{fn_name}(#{args.join(', ')}){
#{body.join(";\n")}
}
JS
        end
      end
    end
  end
end

