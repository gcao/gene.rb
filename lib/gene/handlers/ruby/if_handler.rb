module Gene
  module Handlers
    module Ruby
      class IfHandler
        IF = Gene::Types::Symbol.new 'if'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == IF

          @logger.debug('call', data)

          cond = data.data.shift
          trueExpr = data.data.shift
          falseExpr = data.data.shift

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

