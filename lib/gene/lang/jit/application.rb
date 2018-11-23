require 'forwardable'

module Gene::Lang::Jit
  class Application
    attr_reader :modules
    attr_reader :primary_module

    attr_reader :global
    attr_reader :context

    def initialize primary_module = nil
      @modules        = []
      @global         = Global.new
      if primary_module
        self.primary_module = primary_module
      end
      @vm = VirtualMachine.new(self)
    end

    def primary_module= primary_module
      @primary_module = primary_module
      @modules << primary_module
    end

    def run options = {}
      # @vm.load_module primary_module, options
      run_module primary_module, options
    end

    def run_module mod, options = {}
      @vm.load_module mod, options
    end

    def create_root_context
      Context.new Namespace.new, Scope.new, nil
    end

    def load_core_lib
      core_lib = "#{File.dirname(__FILE__)}/core"
      mod_file = "#{core_lib}.gmod"
      if File.exist? mod_file
        mod = Gene::Lang::Jit::CompiledModule.from_json File.read(mod_file)
      else
        gene_file = "#{core_lib}.gene"
        parsed    = Gene::Parser.parse File.read(gene_file)
        compiler  = Gene::Lang::Jit::Compiler.new
        mod       = compiler.compile parsed
      end

      @modules << mod
      @vm.load_module mod
    end
  end

  class Context
    attr_reader :namespace
    attr_reader :scope
    attr_reader :self

    def initialize namespace, scope, self_
      @namespace = namespace
      @scope     = scope
      @self      = self_
    end

    def extend options = {}
      self.class.new(
        options[:namespace] || @namespace,
        options[:scope]     || @scope,
        options[:self]      || @self
      )
    end

    def def_member name, value, options = {}
      type = options['type']
      if type == 'scope'
        self.scope.def_member name, value, options
      elsif type == 'namespace'
        self.namespace.def_member name, value, options
      elsif self.self.is_a?(NamespaceLike)
        self.self.def_member name, value, options
      else
        self.scope.def_member name, value, options
      end
    end

    def get_member name
      if self.self.is_a?(NamespaceLike)
        self.self.get_member name
      elsif scope && scope.defined?(name)
        scope.get_member name
      elsif namespace && namespace.defined?(name)
        namespace.get_member name
      else
        raise "#{name} is not defined."
      end
    end

    def set_member name, value
      if scope && scope.defined?(name)
        scope.set_member name, value
      elsif namespace && namespace.defined?(name)
        namespace.set_member name, value
      else
        raise "#{name} is not defined."
      end
    end
  end

  module NamespaceLike
    attr_accessor :parent_namespace
    attr_reader :members

    def defined? name
      if @members.include? name
        return true
      elsif parent_namespace
        parent_namespace.defined?(name)
      end
    end

    def def_member name, value, options = {}
      @members[name.to_s] = value
    end

    def get_member name
      name = name.to_s

      if @members.include? name
        @members[name]
      elsif parent_namespace
        parent_namespace.get_member name
      else
        raise "#{name} is not defined."
      end
    end

    def set_member name, value, options = {}
      name = name.to_s

      if @members.include? name
        @members[name] = value
      elsif parent_namespace
        parent_namespace.set_member name, value
      else
        raise "#{name} is not defined."
      end
    end
  end

  class Namespace
    include NamespaceLike

    attr_reader :name

    def initialize name = nil, parent = nil
      @name    = name
      @members = {}
      @parent_namespace  = parent
    end
  end

  class Global
    def initialize
      @members = {}
    end

    def defined? name
      @members.include? name
    end

    def def_member name, value, options = {}
      @members[name.to_s] = value
    end

    def get_member name
      name = name.to_s

      if @members.include? name
        @members[name]
      else
        raise "#{name} is not defined."
      end
    end

    def set_member name, value, options = {}
      name = name.to_s

      if @members.include? name
        @members[name] = value
      else
        raise "#{name} is not defined."
      end
    end
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

    def def_member name, value, options = {}
      self[name] = value
    end

    def set_member name, value
      raise "#{name} is not defined." unless self.defined? name

      if include? name
        self[name] = value
      else
        parent.set_member name, value
      end
    end
  end

  class Function
    include NamespaceLike

    # args are processed in the function body
    attr_reader :name, :body
    attr_reader :inherit_scope
    attr_reader :eval_arguments

    attr_accessor :namespace
    attr_accessor :scope

    def initialize name, body, options = {}
      @name = name
      @body = body

      # inherit_scope is true by default
      if options.has_key? 'inherit_scope'
        @inherit_scope = options['inherit_scope']
      else
        @inherit_scope = true
      end

      # eval_arguments is true by default
      if options.has_key? 'eval_arguments'
        @eval_arguments = options['eval_arguments']
      else
        @eval_arguments = true
      end

      # Required by NamespaceLike
      @members = {}
    end

    # Re-define NamespaceLike methods
    def parent_namespace
      @namespace
    end

    def parent_namespace= namespace
      @namespace = namespace
    end
  end

  class Continuation
    include Forwardable

    attr_accessor :function
    attr_accessor :next_pos
    attr_accessor :registers

    # TODO: fix this
    # def_delegators :@function, :body

    def initialize function
      @function = function
    end

    def body
      @function.body
    end

    def inherit_scope
      @function.inherit_scope
    end

    def scope
      @function.scope
    end

    def namespace
      @function.namespace
    end

    def done?
      @done
    end

    def done= done
      @done = done
    end
  end

  # Module is like Class, except it doesn't include init and parent class
  # TODO: support aspects - before, after, when - works like  before -> when -> method -> when -> after
  # TODO: support meta programming - method_added, method_removed, method_missing
  # TODO: support meta programming - module_created, module_included
  # TODO: Support prepend like how Ruby does
  class Module
    include NamespaceLike

    attr_accessor :name, :methods, :prop_descriptors, :modules

    def initialize name
      @name    = name
      @methods = {}
      @prop_descriptors = {}
      @modules = []
      @members = {}
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

  class HierarchySearch
    attr_accessor :hierarchy, :index

    def initialize(hierarchy)
      @hierarchy = hierarchy
      @index     = -1
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

  class Expandable
    attr_reader :value

    def initialize value = Gene::UNDEFINED
      @value = value
    end
  end

  class Iterator
    def has_next?
    end

    # Parameters for callback vary based on iterator type
    # Array iterator: one arg
    # Map iterator: two args (key, value)
    # Aggregator: two args
    # Throws error has_next? returns false
    def next callback
    end

    # Move forward without invoking callback
    def skip number = 1
    end

    # Can look into what is upcoming
    def can_peek?
    end

    # Use next_index to obtain next value
    # Throw error if can_peek? returns false
    def peek
    end

    # Throws error has_next? returns false
    def next_index
    end

    # Increment an internal index whenever next is called
    # Return current index
    def index
    end

    # Current value
    # Throws error if not started
    def value
    end

    # Return -1 if size is unknown
    # Return -2 if there is no end
    def size
    end

    # call self.next(callback) until the end
    def run callback
    end

    # find first item that callback() returns true
    def find callback
    end

    # find first item that callback() returns false
    def find_not callback
    end

    # return values that callback() return true
    def filter callback
    end
    alias select filter

    # return values that callback() return false
    def filter_not callback
    end
    alias reject filter_not

    # callback takes two arguments, aggregated value, item value
    #   and returns new aggregated value
    def reduce initial_value, callback
    end

    def map callback
    end

    def can_rewind?
    end

    # If next_index is not provided, rewind one step (same as self.rewind(self.index))
    # rewind(0), rewind(-1) will rewind to the beginnig
    # Return true if rewind succeeded
    def rewind next_index = nil
    end

    def restart
      rewind(0)
    end
  end

end