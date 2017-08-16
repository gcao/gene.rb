module Gene
  module Handlers
    module Js
      class IfHandler
        IF = Gene::Types::Ident.new 'if'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.first == IF

          @logger.debug('call', data)

          data.shift
          cond = context.handle_partial data.shift
          trueExpr = context.handle_partial data.shift
          falseExpr = context.handle_partial data.shift

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

