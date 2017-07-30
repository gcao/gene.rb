module Gene
  #
  # Gene will be our own interpreted language
  #
  class GeneLangInterpreter
    attr_reader   :global_scope
    attr_accessor :current_scope

    def initialize
      @handlers = Gene::Handlers::ComboHandler.new
      @handlers.add 100, Gene::Handlers::Lang::ClassHandler.new
      @handlers.add 100, Gene::Handlers::Lang::FunctionHandler.new
      @handlers.add 100, Gene::Handlers::Lang::LetHandler.new
      @handlers.add 100, Gene::Handlers::Lang::BinaryExprHandler.new

      @global_scope  = Gene::Lang::Scope.new nil
      @current_scope = @global_scope
    end

    def scope
      current_scope
    end

    def parse_and_process input
      CoreInterpreter.parse_and_process input do |output|
        process output
      end
    end

    def process data
      if data.is_a? Gene::Types::Group
        @handlers.call self, data
      elsif data.is_a? Gene::Types::Ident
        scope[data.name]
      else
        data
      end
    end
  end
end

