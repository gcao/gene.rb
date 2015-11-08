module Gene
  class RubyInterpreter < AbstractInterpreter
    require 'gene/handlers/ruby/class_handler'
    require 'gene/handlers/ruby/method_handler'
    require 'gene/handlers/ruby/if_handler'
    require 'gene/handlers/ruby/complex_string_handler'
    require 'gene/handlers/ruby/statement_handler'

    def self.parse_and_process input
      output1 = TypesInterpreter.parse_and_process(input)
      new.process(output1)
    end

    def initialize
      super

      @complex_string_handler = Gene::Handlers::Ruby::ComplexStringHandler.new

      @handlers = [
        Gene::Handlers::Ruby::ClassHandler.new,
        Gene::Handlers::Ruby::MethodHandler.new,
        Gene::Handlers::Ruby::IfHandler.new,
        Gene::Handlers::Ruby::StatementHandler.new,
      ]
    end

    # Override with additional logic
    def handle_partial data
      result = super

      # TODO there must be a better way to invoke handler for custom types
      if result.is_a? Gene::Types::ComplexString
        result = @complex_string_handler.call self, data
      end

      result
    end

  end
end

