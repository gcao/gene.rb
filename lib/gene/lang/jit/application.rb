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

    def run options = {}
      vm      = VirtualMachine.new(self)
      primary_module.blocks.each do |_, block|
        vm.add_block block
      end
      block   = primary_module.primary_block
      vm.process block, options
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

    def extend options = {}
      self.class.new(
        self,
        options[:namespace] || @namespace,
        options[:scope]     || @scope,
        options[:self]      || @self
      )
    end

    def def_member name, value, options = {}
      if self.self.is_a? Namespace
        self.self.def_member name, value
      else
        self.scope.set_member name, value, options
      end
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
    attr_reader :name
    attr_reader :parent

    def initialize name = nil, parent = nil
      @name   = name
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

    def let name, value
      raise "#{name} is not defined." unless self.defined? name

      if include? name
        self[name] = value
      else
        parent.let name, value
      end
    end
  end

  class Function
    # args are processed in the function body
    attr_reader :name, :body
    attr_reader :inherit_scope
    attr_reader :eval_arguments

    def initialize name, body, options = {}
      @name = name
      @body = body

      # inherit_scope is true by default
      if options.has_key? :inherit_scope
        @inherit_scope  = options[:inherit_scope]
      else
        @inherit_scope  = true
      end

      # inherit_scope is false by default
      @eval_arguments = options[:eval_arguments]
    end
  end

  # Module is like Class, except it doesn't include init and parent class
  # TODO: support aspects - before, after, when - works like  before -> when -> method -> when -> after
  # TODO: support meta programming - method_added, method_removed, method_missing
  # TODO: support meta programming - module_created, module_included
  # TODO: Support prepend like how Ruby does
  class Module < Gene::Lang::Object
    attr_accessor :name, :methods, :prop_descriptors, :modules
    attr_accessor :scope

    def initialize name
      super(Class)
      set 'name', name
      set 'methods', {}
      set 'prop_descriptors', {}
      set 'modules', []
    end

    def properties_to_hide
      %w()
    end

    def add_method method
      methods[method.name.to_s] = method
    end

    def method name
      methods[name]
    end

    # include myself
    def ancestors
      return @ancestors if @ancestors

      @ancestors = [self]
      modules.each do |mod|
        @ancestors += mod.ancestors
      end
      @ancestors
    end

    # BEGIN: Implement Namespace-like interface
    def defined? name
      scope.defined? name
    end

    def get_member name
      scope.get_member name
    end

    def def_member name, value
      scope.def_member name, value
    end

    def set_member name, value, options
      scope.set_member name, value, options
    end

    def members
      scope.variables
    end
    # END

    # def handle_method options
    #   method_name = options[:method]
    #   m = method(method_name)
    #   if m
    #     m.call options
    #   else
    #     hierarchy = options[:hierarchy]
    #     next_class_or_module = hierarchy.next
    #     if next_class_or_module
    #       next_class_or_module.handle_method options
    #     else
    #       #TODO: throw error or invoke method_missing
    #       raise "Undefined method #{method} for #{options[:self]}"
    #     end
    #   end
    # end
  end

  # TODO: change to single inheritance and include modules like Ruby
  # TODO: support meta programming - class_created, class_extended
  class Class < Module
    attr_accessor :parent_class

    def initialize name
      super(name)
      self.class = Class
    end

    # def parent_class
    #   return nil if self == Gene::Lang::Object

    #   get('parent_class') || Gene::Lang::Object
    # end

    # include myself
    def ancestors
      return @ancestors if @ancestors

      @ancestors = [self]
      modules.each do |mod|
        @ancestors += mod.ancestors
      end
      if parent_class
        @ancestors += parent_class.ancestors
      end
      @ancestors
    end
  end

  # An algorithm to lazily calculate a class/module's ancestors hierarchy
  # Create a new array to store the hierarchy
  # Push the class itself to the hierarchy
  # Save the class's parent class and modules in a temporary stack
  # When trying to access next item in the hierarchy
  # Check whether the stack is empty
  # If not, pop up the last item, add to the hierarchy
  # And push the parent class + modules to the end of the stack
  # If the stack is empty, add Object to the hierarchy and mark the hierarchy as complete
  #
  # When do we invalidate the hierarchy?
  # Each class/module store a number that represents number of modifications
  # When hierarchy is calculated, the number is cached
  # Increment modifications when the class/module is extended, included, unincluded
  # If the cached number is smaller than the current modification number, it should be re-calculated
  #
  # What do we do if one of our parent or grandparent module/class has changed?
  # In our ancestors cache, store the list of ancestors and their modification number, validate it on use

  class HierarchySearch < Gene::Lang::Object
    attr_accessor :hierarchy, :index

    def initialize(hierarchy)
      super(HierarchySearch)
      set 'hierarchy', hierarchy
      set 'index', -1
    end

    def next
      self.index += 1
      hierarchy[self.index]
    end

    def current
      hierarchy[self.index]
    end

    # Find method in the hierarchy
    def method name, options = {}
      while index < hierarchy.length
        module_or_class = hierarchy[index]
        method = module_or_class.method(name)
        if method
          return method
        end
        self.index += 1
      end

      if not options[:do_not_throw_error]
        raise "Method \"#{name}\" is not found."
      end
    end
  end

  class Expandable < Gene::Lang::Object
    attr_reader :value

    def initialize value = Gene::UNDEFINED
      super(Expandable)
      set 'value', value
    end
  end

end