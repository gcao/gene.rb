require 'gene/handlers/js/literal_handler'
require 'gene/handlers/js/class_handler'
require 'gene/handlers/js/object_handler'
require 'gene/handlers/js/function_handler'
require 'gene/handlers/js/var_handler'
require 'gene/handlers/js/if_handler'
require 'gene/handlers/js/return_handler'
#require 'gene/handlers/js/complex_string_handler'
require 'gene/handlers/js/invocation_handler'
#require 'gene/handlers/js/assignment_handler'
require 'gene/handlers/js/expression_handler'
require 'gene/handlers/js/statement_handler'

module Gene
  class JavascriptInterpreter < AbstractInterpreter

    def self.parse_and_process input, &block
      interpreter = new

      CoreInterpreter.parse_and_process input do |output|
        interpreter.process output, &block
      end
    end

    def initialize
      super

      @handlers.add Gene::Handlers::Js::LiteralHandler.new, 100
      #@handlers.add Gene::Handlers::Js::ComplexStringHandler.new, 100
      @handlers.add Gene::Handlers::Js::ClassHandler.new, 100
      @handlers.add Gene::Handlers::Js::ObjectHandler.new, 100
      @handlers.add Gene::Handlers::Js::FunctionHandler.new, 100
      @handlers.add Gene::Handlers::Js::VarHandler.new, 100
      @handlers.add Gene::Handlers::Js::IfHandler.new, 100
      @handlers.add Gene::Handlers::Js::ReturnHandler.new, 100
      @handlers.add Gene::Handlers::Js::ExpressionHandler.new, 100
      @handlers.add Gene::Handlers::Js::InvocationHandler.new, 100
      #@handlers.add Gene::Handlers::Js::AssignmentHandler.new, 100
      @handlers.add Gene::Handlers::Js::StatementHandler.new, 100
    end

  end
end

