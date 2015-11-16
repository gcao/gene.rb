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
      new.process(Parser.parse(input), &block)
    end

    def initialize
      super

      @handlers = [
        Gene::Handlers::ArrayHandler.new,
        Gene::Handlers::HashHandler.new,
        Gene::Handlers::ComplexStringHandler.new,
        Gene::Handlers::RangeHandler.new,
        Gene::Handlers::Base64Handler.new,
        Gene::Handlers::ComplexStringHandler.new,
        Gene::Handlers::MetadataHandler.new,
        Gene::Handlers::ReferenceHandler.new,

        Gene::Handlers::Ruby::ComplexStringHandler.new,
        Gene::Handlers::Ruby::ModuleHandler.new,
        Gene::Handlers::Ruby::ClassHandler.new,
        Gene::Handlers::Ruby::MethodHandler.new,
        Gene::Handlers::Ruby::IfHandler.new,
        Gene::Handlers::Ruby::InvocationHandler.new,
        Gene::Handlers::Ruby::AssignmentHandler.new,
        Gene::Handlers::Ruby::StatementHandler.new,
      ]
    end

  end
end

