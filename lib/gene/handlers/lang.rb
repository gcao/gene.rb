module Gene::Handlers::Lang
  class LetHandler
    LET = Gene::Types::Ident.new('let')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless LET.first_of_group? data
      name = data[1].to_s
      value = context.process data[2]
      context.scope.set name, value
      Gene::Lang::Variable.new name, value
    end
  end
end

require 'gene/handlers/lang/class_handler'
require 'gene/handlers/lang/function_handler'
require 'gene/handlers/lang/binary_expr_handler'
require 'gene/handlers/lang/invocation_handler'
