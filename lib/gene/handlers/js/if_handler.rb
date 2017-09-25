module Gene
  module Handlers
    module Js
      class IfHandler
        IF = Gene::Types::Symbol.new 'if'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == IF

          @logger.debug('call', data)

          cond = context.handle_partial data.data.shift
          trueExpr = context.handle_partial data.data.shift
          falseExpr = context.handle_partial data.data.shift

<<-RUBY
if (#{cond}) {
#{trueExpr}#{if falseExpr then "\n} else {\n#{falseExpr}" end}
}
RUBY
        end
      end
    end
  end
end

