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

    def self.parse_and_process input, &block
      interpreter = new

      CoreInterpreter.parse_and_process input do |output|
        interpreter.process output, &block
      end
    end

    def initialize
      super

      @handlers.add Gene::Handlers::ArrayHandler.new, 100
      @handlers.add Gene::Handlers::HashHandler.new, 100
      @handlers.add Gene::Handlers::ComplexStringHandler.new, 100
      @handlers.add Gene::Handlers::RangeHandler.new, 100
      @handlers.add Gene::Handlers::Base64Handler.new, 100
      @handlers.add Gene::Handlers::RegexpHandler.new, 100
      @handlers.add Gene::Handlers::RefHandler.new, 100

      @handlers.add Gene::Handlers::Ruby::ComplexStringHandler.new, 100
      @handlers.add Gene::Handlers::Ruby::ModuleHandler.new, 100
      @handlers.add Gene::Handlers::Ruby::ClassHandler.new, 100
      @handlers.add Gene::Handlers::Ruby::MethodHandler.new, 100
      @handlers.add Gene::Handlers::Ruby::IfHandler.new, 100
      @handlers.add Gene::Handlers::Ruby::InvocationHandler.new, 100
      @handlers.add Gene::Handlers::Ruby::AssignmentHandler.new, 100
      @handlers.add Gene::Handlers::Ruby::StatementHandler.new, 100
    end

  end
end

