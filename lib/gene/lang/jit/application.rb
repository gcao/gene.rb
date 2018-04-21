module Gene::Lang::Jit
  class Application
    attr_reader :modules
    attr_reader :primary_module

    attr_reader :global_namespace
    attr_reader :context

    def initialize primary_module
      @modules          = []
      @primary_module   = primary_module
      @global_namespace = Namespace.new
    end

    def run
      context = create_root_context
      VirtualMachine.new(self).process context, primary_module
    end

    def create_root_context
      Context.new nil, Namespace.new(@global_namespace), Scope.new, nil
    end
  end

  class Context
    attr_reader :parent
    attr_reader :namespace
    attr_reader :scope
    attr_reader :self

    def initialize parent, namespace, scope, self_
      @parent    = parent
      @namespace = namespace
      @scope     = scope
      @self      = self_
    end

    def extend options
      self.class.new(
        self,
        options[:namespace] || @namespace,
        options[:scope]     || @scope,
        options[:self]      || @self
      )
    end
  end

  class Namespace
    attr_reader :parent

    def initialize parent = nil
      @parent = parent
    end
  end

  class Scope
    def initialize parent = nil
      @parent = parent
    end
  end
end