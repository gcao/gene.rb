module Gene::Handlers::Lang
  class InitHandler
    INIT = Gene::Types::Ident.new('init')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless INIT.first_of_group? data
      name = INIT.name
      fn = Gene::Lang::Function.new name
      arguments = [data.second].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.block = Gene::Lang::Block.new arguments, data[2..-1]
      context.scope[name] = fn
      fn
    end
  end

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
