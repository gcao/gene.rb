require 'gene/handlers/ruby/module_handler'
require 'gene/handlers/ruby/class_handler'
require 'gene/handlers/ruby/method_handler'
require 'gene/handlers/ruby/if_handler'
require 'gene/handlers/ruby/complex_string_handler'
require 'gene/handlers/ruby/invocation_handler'
require 'gene/handlers/ruby/statement_handler'
require 'gene/handlers/ruby/assignment_handler'

module Gene
  class RubyInterpreter < AbstractInterpreter

    def initialize
      super

      @handlers.add 100, Gene::Handlers::Ruby::ComplexStringHandler.new
      @handlers.add 100, Gene::Handlers::Ruby::ModuleHandler.new
      @handlers.add 100, Gene::Handlers::Ruby::ClassHandler.new
      @handlers.add 100, Gene::Handlers::Ruby::MethodHandler.new
      @handlers.add 100, Gene::Handlers::Ruby::IfHandler.new
      @handlers.add 100, Gene::Handlers::Ruby::InvocationHandler.new
      @handlers.add 100, Gene::Handlers::Ruby::AssignmentHandler.new
      @handlers.add 200, Gene::Handlers::Ruby::StatementHandler.new
    end

  end
end

