require 'forwardable'

module Gene::Lang::Jit
  class Application
    attr_accessor :global
    attr_accessor :last_result

    def initialize
      reset
    end

    # Application can be reset to initial state.
    # This is mainly created for unit tests.
    def reset
      @global = Global.new
    end

    def set_param name, value
      @global.params.def_member name.to_s, value
    end

    def run mod, options = {}
      VirtualMachine.new.load_module mod, options
    end

    def create_root_context
      Context.new Namespace.new, Scope.new, nil
    end

    def load_core_lib
      core_lib = "#{File.dirname(__FILE__)}/core"
      mod = CODE_MGR.load_from_path core_lib
      VirtualMachine.new.load_module mod
      @core_lib_loaded = true
    end

    def get_class obj
      if @core_lib_loaded
        case obj
        when String
          gene.get_member('String')
        when Array
          gene.get_member('Array')
        when Hash
          gene.get_member('Map')
        when File
          gene.get_member('File')
        when Dir
          gene.get_member('Dir')
        else
          obj.class
        end
      else
        obj.class
      end
    end

    # Cache gene object
    def gene
      @gene ||= global.get_member('gene')
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
      elsif member_resolver and found = member_resolver.call_with_self(self, name)
        found
      elsif parent_namespace
        parent_namespace.get_member name
      else
        raise "#{name} is not defined."
      end
    end

    def member_resolver
      @member_resolver ||= @members['member_resolver']
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
      @members['params'] = Namespace.new
    end

    def params
      @members['params']
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

  # A generic block that can represent a ns/module/class's body or any block of code
  # It does not take arguments
  # It may or may not inherit parent's scope
  # It can probably be removed after execution
  class Block
    attr_reader :name, :body
    attr_reader :inherit_scope
    attr_accessor :namespace
    attr_accessor :scope

    def initialize name, body, options = {}
      @name = name
      @body = body
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

    attr_accessor :app

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

    def call *args
      VirtualMachine.new.process_function self, args
    end

    def call_with_self _self, *args
      VirtualMachine.new.process_function self, args, self: _self
    end

    def to_proc
      Proc.new do |*args|
        self.call *args
      end
    end

    def to_s
      "#<#{self.class.name} @name=\"#{name}\" ...>"
    end
    alias inspect to_s

  end

  # A function bounded to a self object
  # TODO
  class BoundedFunction
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

    def get_method name
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
      @index     = 0
    end

    def next
      self.index += 1
      hierarchy[self.index]
    end

    def current
      hierarchy[self.index]
    end

    # Find method in the hierarchy
    def get_method name, options = {}
      while index < hierarchy.length
        module_or_class = hierarchy[index]
        method = module_or_class.get_method(name)
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

  class FileSystemObject
    DIR  = "DIR"
    FILE = "FILE"

    attr_accessor :type
    attr_reader :path

    def initialize path
      @path = path
    end

    # Mimic readonly namespace
    def get_member name
      if file?
        raise "File object can not have child members: #{path}"
      else
        new_path = path + '/' + name
        self.class.new new_path
      end
    end

    def exist?
      File.exist?(path)
    end

    def file?
      File.file?(path)
    end

    def directory?
      File.directory?(path)
    end
  end

  # The global application object
  APP = Gene::Lang::Jit::Application.new
end
