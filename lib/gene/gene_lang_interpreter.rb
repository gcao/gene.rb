module Gene
  #
  # Gene will be our own interpreted language
  #
  class GeneLangInterpreter
    attr_reader   :global_scope

    def initialize
      @handlers = Gene::Handlers::ComboHandler.new
      @handlers.add 100, Gene::Handlers::Lang::DefaultHandler.new
      @handlers.add 100, Gene::Handlers::Lang::ClassHandler.new
      @handlers.add 100, Gene::Handlers::Lang::MethodHandler.new
      @handlers.add 100, Gene::Handlers::Lang::FunctionHandler.new
      @handlers.add 100, Gene::Handlers::Lang::LetHandler.new
      @handlers.add 100, Gene::Handlers::Lang::NewHandler.new
      @handlers.add 100, Gene::Handlers::Lang::InitHandler.new
      @handlers.add 100, Gene::Handlers::Lang::BinaryExprHandler.new
      @handlers.add 100, Gene::Handlers::Lang::InvocationHandler.new

      reset
    end

    def reset
      # global_scope is a special scope
      # root_scope is the root of regular scope hierarchy: @scopes
      # regular scopes can inherit or not inherit from a higher level scope
      @global_scope = Gene::Lang::Scope.new nil
      @root_scope   = Gene::Lang::Scope.new nil
      @scopes       = [@root_scope]
      @self_objects = []
    end

    def scope
      @scopes.last
    end

    def start_scope scope = Gene::Lang::Scope.new(nil)
      @scopes.push scope
    end

    def end_scope
      throw "Scope error: can not close the root scope." if @scopes.size == 0
      @scopes.pop
    end

    def self
      @self_objects.last
    end

    def start_self self_object
      @self_objects.push self_object
    end

    def end_self
      @self_objects.pop
    end

    def parse_and_process input
      CoreInterpreter.parse_and_process input do |output|
        process output
      end
    end

    def process data
      @handlers.call self, data
    end
  end
end

