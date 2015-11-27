require 'gene/handlers/js/class_handler'
require 'gene/handlers/js/function_handler'
#require 'gene/handlers/js/if_handler'
#require 'gene/handlers/js/complex_string_handler'
#require 'gene/handlers/js/invocation_handler'
#require 'gene/handlers/js/statement_handler'
#require 'gene/handlers/js/assignment_handler'

module Gene
  class JavascriptInterpreter < AbstractInterpreter

    def self.parse_and_process input, &block
      new.process(Parser.parse(input), &block)
    end

    def initialize
      super

      @handlers.push(
        #Gene::Handlers::Js::ComplexStringHandler.new,
        Gene::Handlers::Js::ClassHandler.new,
        Gene::Handlers::Js::FunctionHandler.new,
        #Gene::Handlers::Js::IfHandler.new,
        #Gene::Handlers::Js::InvocationHandler.new,
        #Gene::Handlers::Js::AssignmentHandler.new,
        #Gene::Handlers::Js::StatementHandler.new,
      )
    end

  end
end

