module Gene
  module Handlers
    module Ruby
      class IfHandler < Base
        IF = Gene::Types::Ident.new 'if'

        def call group
          @logger.debug('call', group)
          return Gene::NOT_HANDLED unless group.first == IF

          group.shift
          cond = group.shift
          trueExpr = group.shift
          falseExpr = group.shift


<<-RUBY
if (#{cond})
#{trueExpr}
#{if falseExpr then "\nelse\n#{falseExpr}" end}
end
RUBY
        end
      end
    end
  end
end

