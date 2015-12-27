module Gene
  module Handlers
    module Ruby
      class IfHandler
        IF = Gene::Types::Ident.new 'if'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group and data.first == IF

          @logger.debug('call', data)

          data.shift
          cond = data.shift
          trueExpr = data.shift
          falseExpr = data.shift

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

