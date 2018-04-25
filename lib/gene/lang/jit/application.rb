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

    def def_member name, value, options = {}
      # if self.self.is_a? Namespace
      #   self.self.def_member name, value
      # else
        self.scope.set_member name, value, options
      # end
    end

    def get_member name
      if scope && scope.defined?(name)
        scope.get_member name
      elsif namespace && namespace.defined?(name)
        namespace.get_member name
      else
        raise "#{name} is not defined."
      end
    end

    def set_member name, value
      # if self.self.is_a? Namespace
      #   self.self.set_member name, value
      # elsif self.scope.defined? name
      #   self.scope.let name, value
      # else
      #   self.namespace.set_member name, value
      # end
      self.scope.let name, value
    end
  end

  class Namespace < Hash
    attr_reader :parent

    def initialize parent = nil
      @parent = parent
    end

    def defined? name
      if include? name
        return true
      end
      if parent
        parent.defined?(name)
      end
    end

    def get_member name
      name = name.to_s

      if include? name
        self[name]
      elsif self.parent
        self.parent.get_member name
      else
        # Gene::UNDEFINED
        nil
      end
    end

    def set_member name, value, options = {}
      self[name] = value
    end
    alias def_member set_member
  end

  class Scope < Hash
    attr_reader :parent
    attr_reader :inherit_variables

    def initialize parent = nil, inherit_variables = false
      @parent            = parent
      @inherit_variables = inherit_variables
    end

    def defined? name
      if include?(name)
        return true
      end
      if parent
        if inherit_variables
          parent.defined?(name)
        end
      end
    end

    def get_member name
      name = name.to_s

      if include? name
        self[name]
      elsif self.parent
        if inherit_variables
          self.parent.get_member name
        end
      else
        # Gene::UNDEFINED
        nil
      end
    end

    def set_member name, value, options = {}
      self[name] = value
    end
    alias def_member set_member
  end
end