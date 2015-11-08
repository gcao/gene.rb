module Gene
  module Handlers
    module Ruby
      class IfHandler
        IF = Gene::Types::Ident.new 'if'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED unless group.first == IF

          @logger.debug('call', group)

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

