module Gene
  module Handlers
    module Js
      class IfHandler
        IF = Gene::Types::Ident.new 'if'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED unless group.first == IF

          @logger.debug('call', group)

          group.shift
          cond = context.handle_partial group.shift
          trueExpr = context.handle_partial group.shift
          falseExpr = context.handle_partial group.shift

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

