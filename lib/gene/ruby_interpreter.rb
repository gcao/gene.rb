module Gene
  class RubyInterpreter < AbstractInterpreter
    require 'gene/handlers/ruby/class_handler'
    require 'gene/handlers/ruby/method_handler'
    require 'gene/handlers/ruby/if_handler'
    require 'gene/handlers/ruby/statement_handler'

    def self.parse_and_process input
      output1 = TypesInterpreter.parse_and_process(input)
      new.process(output1)
    end

    def initialize
      super
      @handlers = [
        Gene::Handlers::Ruby::ClassHandler.new,
        Gene::Handlers::Ruby::MethodHandler.new,
        Gene::Handlers::Ruby::IfHandler.new,
        Gene::Handlers::Ruby::StatementHandler.new,
      ]
    end

  end
end

