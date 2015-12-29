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

    def initialize
      super

      @handlers.add 100, Gene::Handlers::Js::LiteralHandler.new
      #@handlers.add 100, Gene::Handlers::Js::ComplexStringHandler.new
      @handlers.add 100, Gene::Handlers::Js::ClassHandler.new
      @handlers.add 100, Gene::Handlers::Js::ObjectHandler.new
      @handlers.add 100, Gene::Handlers::Js::FunctionHandler.new
      @handlers.add 100, Gene::Handlers::Js::VarHandler.new
      @handlers.add 100, Gene::Handlers::Js::IfHandler.new
      @handlers.add 100, Gene::Handlers::Js::ReturnHandler.new
      @handlers.add 100, Gene::Handlers::Js::ExpressionHandler.new
      @handlers.add 100, Gene::Handlers::Js::InvocationHandler.new
      #@handlers.add 100, Gene::Handlers::Js::AssignmentHandler.new
      @handlers.add 100, Gene::Handlers::Js::StatementHandler.new
    end

  end
end

