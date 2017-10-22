module Gene::Lang
  # All objects other than literals have this structure
  # type: a short Symbol to help identify type of the object
  # properties: Hash
  #   ...
  # data: literal or array or anything else
  #
  # type is stored in properties with key '#type'
  # data is stored in properties with key '#data'
  # class is stored in properties with key '#class'
  class Object
    attr_accessor :properties

    def initialize klass = Object
      @properties = {}
      @klass      = klass
    end

    def class
      @klass
    end

    def class= klass
      @klass = klass
    end

    def get name
      @properties[name]
    end
    alias [] get

    def set name, value
      @properties[name] = value
    end
    alias []= set

    # Return #data - should always be an array or undefined
    def data
      @properties['#data']
    end

    def data= data
      set '#data', data
    end

    def as klass
      obj = Object.new klass
      obj.properties = @properties
      obj
    end

    def to_s
      parts = []
      type = self.class ? self.class.name : Object.name
      parts << type.sub(/^Gene::Lang::/, '')

      @properties.each do |name, value|
        next if name.to_s =~ /^\$/
        next if %W(#class #data).include? name.to_s

        if value == true
          parts << "^^#{name}"
        elsif value == false
          parts << "^!#{name}"
        else
          parts << "^#{name}" << value.inspect
        end
      end

      if @properties.include? "#data"
        parts << @properties["#data"].inspect
      end

      "(#{parts.join(' ')})"
    end
    alias inspect to_s

    def self.attr_reader *names
      names.each do |name|
        name = name.to_s
        define_method(name) do
          @properties[name.to_s]
        end
      end
    end

    def self.attr_accessor *names
      names.each do |name|
        name = name.to_s
        define_method(name) do
          @properties[name]
        end
        define_method("#{name}=") do |value|
          @properties[name] = value
        end
      end
    end

    def self.handle_method options
      context      = options[:context]
      object_class = context.get_member('Object')
      method_name  = options[:method]
      method       = object_class.method(method_name)
      if method
        method.call options
      else
        _self      = options[:self]
        args       = options[:arguments]
        if args.is_a? Gene::Lang::Object
          _self.send method_name, *args.data
        else
          _self.send method_name, *args
        end
      end
    end

    def self.from_array data
      obj = new
      obj.data = data
      obj
    end
  end

  class Application < Object
    attr_accessor :global_namespace

    def initialize
      super(Application)

      set 'global_namespace', Gene::Lang::Namespace.new('global', nil)
    end

    def create_root_context
      context = Context.new
      context.application = self
      # Create an anonymous namespace
      context.self = context.namespace = Gene::Lang::Namespace.new(nil, global_namespace)
      context
    end

    def parse_and_process code, options = {}
      context = create_root_context
      context.define '__DIR__',  options[:dir]
      context.define '__FILE__', options[:file]
      interpreter = Gene::Lang::Interpreter.new context
      interpreter.parse_and_process code
    end

    def load_core_libs
      dir  = File.dirname(__FILE__)
      file = "#{dir}/core.gene"
      parse_and_process File.read(file), dir: dir, file: file
    end
  end

  class Context < Object
    attr_accessor :global_namespace, :namespace, :scope, :self
    def initialize
      super(Context)
    end

    def extend options
      new_context             = Context.new
      new_context.application = @application
      new_context.global_namespace = @application.global_namespace
      new_context.namespace   = options[:namespace] || namespace
      new_context.scope       = options[:scope]     || scope
      new_context.self        = options[:self]
      new_context
    end

    def interpreter
      @interpreter ||= Gene::Lang::Interpreter.new self
    end

    def application
      @application
    end

    def application= application
      @application = application
    end

    def get_member name
      if scope && scope.defined?(name)
        scope.get_member name
      elsif namespace && namespace.defined?(name)
        namespace.get_member name
      elsif global_namespace.defined?(name)
        global_namespace.get_member name
      else
        raise "#{name} is not defined."
      end
    end

    def define name, value
      if self.self.is_a? Namespace
        self.self.def_member name, value
      else
        self.scope.set_member name, value
      end
    end

    def set_member name, value
      if self.self.is_a? Namespace
        self.self.set_member name, value
      elsif self.scope.defined? name
        self.scope.let name, value
      else
        self.namespace.set_member name, value
      end
    end

    def set_global name, value
      application.global_namespace.def_member name, value
    end

    def process data
      interpreter.process data
    end

    def process_statements statements
      result = Gene::UNDEFINED
      return result if statements.nil?

      statements.each do |stmt|
        result = process stmt
        if result.is_a?(Gene::Lang::ReturnValue) or result.is_a?(Gene::Lang::BreakValue)
          break
        end
      end

      result
    end
  end

  # Module is like Class, except it doesn't include init and parent class
  # TODO: support aspects - before, after, when - works like  before -> when -> method -> when -> after
  # TODO: support meta programming - method_added, method_removed, method_missing
  # TODO: support meta programming - module_created, module_included
  # TODO: Support prepend like how Ruby does
  class Module < Object
    attr_accessor :name, :methods, :prop_descriptors, :modules
    def initialize name
      super(Class)

      set 'name', name
      set 'methods', {}
      set 'prop_descriptors', {}
      set 'modules', []
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

    def handle_method options
      method_name = options[:method]
      m = method(method_name)
      if m
        m.call options
      else
        hierarchy = options[:hierarchy]
        next_class_or_module = hierarchy.next
        if next_class_or_module
          next_class_or_module.handle_method options
        else
          #TODO: throw error or invoke method_missing
        end
      end
    end
  end

  # TODO: change to single inheritance and include modules like Ruby
  # TODO: support meta programming - class_created, class_extended
  class Class < Module
    attr_accessor :parent_class
    def initialize name
      super(name)
    end

    def parent_class
      return nil if self == Gene::Lang::Object

      get('parent_class') || Gene::Lang::Object
    end

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
  # each class/module store a number and increment when it is extended, included, unincluded

  class HierarchySearch < Object
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
  end

  class Function < Object
    attr_reader :name
    attr_accessor :parent_scope, :args_matcher, :statements
    attr_accessor :inherit_scope, :eval_arguments
    def initialize name
      super(Function)

      set 'name', name
      self.inherit_scope  = true # Default inherit_scope to true
      self.eval_arguments = true # Default eval_arguments to true
    end

    def call options = {}
      scope = Scope.new parent_scope, inherit_scope
      context = options[:context]

      scope.set_member '$method', options[:method] if options[:method]
      scope.set_member '$hierarchy', options[:hierarchy] if options[:hierarchy]

      scope.set_member '$function', self
      scope.set_member '$caller-context', context
      scope.set_member '$arguments', options[:arguments]
      scope.arguments = Gene::Lang::ArgumentsScope.new options[:arguments], self.args_matcher

      new_context = context.extend scope: scope, self: options[:self]
      result = new_context.process_statements statements
      if result.is_a? ReturnValue
        result = result.value
      end
      result
    end
  end

  class Property < Object
    attr_reader :name, :type, :getter, :setter
    def initialize name
      super(Property)

      set 'name', name
    end
  end

  class PropertyName < Object
    attr_reader :name
    def initialize name
      super(PropertyName)

      set 'name', name
    end
  end

  class Scope < Object
    attr_accessor :parent, :variables, :arguments, :inherit_variables

    def initialize parent, inherit_variables
      super(Scope)
      set 'parent', parent
      set 'variables', {}
    end

    def defined? name
      self.variables.keys.include?(name)                  or
      (self.arguments and self.arguments.defined?(name))  or
      (self.parent and self.parent.defined?(name))
    end

    def get_member name
      name = name.to_s

      if self.variables.keys.include? name
        self.variables[name]
      elsif self.arguments and self.arguments.defined?(name)
        self.arguments.get_member(name)
      elsif self.parent
        self.parent.get_member name
      else
        Gene::UNDEFINED
      end
    end

    def set_member name, value
      self.variables[name] = value
    end

    def let name, value
      raise "#{name} is not defined." unless self.defined? name

      if self.variables.keys.include? name
        self.variables[name] = value
      elsif self.arguments and self.arguments.defined?(name)
        self.arguments.set_member name, value
      elsif self.parent and self.parent.defined?(name)
        self.parent.let name, value
      else
        self.variables[name] = value
      end
    end
  end

  class Namespace < Object
    attr_reader :name, :parent, :members, :public_members
    def initialize name, parent
      super(Namespace)

      set 'name', name
      set 'parent', parent
      set 'members', {}
      set 'public_members', []
    end

    def defined? name
      members.include?(name) || (parent && parent.defined?(name))
    end

    def get_member name
      if members.include? name
        members[name]
      elsif parent
        parent.members[name]
      end
    end

    def def_member name, value
      members[name] = value
      set_access_level name, 'public'
    end

    def set_member name, value
      if members.include? name
        members[name] = value
      elsif parent
        parent.set_member name, value
      else
        raise "Unknown member '#{name}'"
      end
    end

    def set_access_level name, access_level
      if access_level.to_s == 'public'
        public_members.push name unless public_members.include? name
      elsif access_level.to_s == 'private'
        public_members.delete name
      end
    end

    def get_access_level name
      public_members.include?(name) ? 'public' : 'private'
    end
  end

  class ArgumentsScope < Object
    attr_accessor :arguments, :matcher

    def initialize arguments, matcher
      super(ArgumentsScope)
      set 'arguments', arguments
      set 'matcher',   matcher
    end

    def defined? name
      matcher.defined? name
    end

    def get_member name
      m = matcher.get_matcher name
      return unless m

      if m.is_a? DataMatcher
        if m.expandable
          arguments.data[m.index .. m.end_index]
        else
          arguments.data[m.index]
        end
      else
        arguments.get m.name
      end
    end

    def set_member name, value
      m = matcher.get_matcher name
      return unless m

      if m.is_a? DataMatcher
        if m.expandable
          arguments.data[m.index .. m.end_index] = value
        else
          arguments.data[m.index] = value
        end
      else
        arguments.set name, value
      end
    end
  end

  class Matcher < Object
    attr_accessor :data_matchers, :prop_matchers

    def initialize
      super(Matcher)
      set 'data_matchers', []
      set 'prop_matchers', {}
    end

    def defined? name
      prop_matchers[name] or data_matchers.find {|matcher| matcher.name == name }
    end

    def all_matchers
      return @all_matchers if @all_matchers

      @all_matchers = prop_matchers.clone
      data_matchers.each do |matcher|
        @all_matchers[matcher.name] = matcher
      end
      @all_matchers
    end

    def get_matcher name
      all_matchers[name]
    end

    # TODO: support `^arg...`
    def from_array array
      array = [array] unless array.is_a? ::Array

      data_matcher = nil

      while not array.empty?
        item = array.shift.to_s

        if item == '='
          if data_matcher
            data_matcher.default_value = array.shift
            data_matcher = nil
          else
            raise 'Syntax error: argument name is expected before `=`'
          end

        elsif item =~ /^\^\^(.*)$/
          name = $1
          raise "Name conflict: #{name}" if self.defined? name
          prop_matchers[name] = Gene::Lang::PropMatcher.new name
          data_matcher = nil

        elsif item =~ /^\^(.*)$/
          name = $1
          raise "Name conflict: #{name}" if self.defined? name
          prop_matcher = Gene::Lang::PropMatcher.new name
          prop_matcher.default_value = array.shift
          prop_matchers[name] = prop_matcher
          data_matcher = nil

        else
          if item =~ /^(.*)(\.\.\.)$/
            name       = $1
            expandable = true
          else
            name       = item
            expandable = false
          end
          raise "Name conflict: #{name}" if self.defined? name
          data_matcher = Gene::Lang::DataMatcher.new name
          data_matcher.expandable = expandable
          data_matchers << data_matcher
        end
      end

      calc_indexes
    end

    private

    def calc_indexes
      return if data_matchers.size == 0

      data_matchers.each_with_index do |matcher, i|
        matcher.index = i
      end

      last = data_matchers[-1]
      if last.expandable
        last.end_index = -1
      end
    end
  end

  # [name]
  # [name = 'Default value']
  # [rest...]: default to []
  class DataMatcher < Object
    attr_reader :name
    attr_accessor :index, :end_index, :expandable, :default_value

    def initialize name
      super(DataMatcher)
      set 'name', name
      set 'default_value', Gene::UNDEFINED
    end
  end

  # [^^attr]
  # [^attr 'Default value']
  # [^^attrs...]: default to {}
  class PropMatcher < Object
    attr_reader :name
    attr_accessor :expandable, :default_value

    def initialize name
      super(PropMatcher)
      set 'name', name
      set 'default_value', Gene::UNDEFINED
    end
  end

  class Assignment < Object
    attr_reader :variable, :expression

    def initialize variable, expression = nil
      super(Assignment)
      set 'variable', variable
      set 'expression', expression
    end
  end

  class Variable < Object
    attr_reader :name
    attr_accessor :value
    def initialize name, value = nil
      super(Variable)

      set 'name', name
      set 'value', value
    end
  end

  class ReturnValue < Object
    attr_reader :value
    def initialize value = Gene::UNDEFINED
      super(ReturnValue)

      set 'value', value
    end
  end

  class BreakValue < Object
    attr_reader :value
    def initialize value = Gene::UNDEFINED
      super(BreakValue)

      set 'value', value
    end
  end

  class Expandable < Object
    attr_reader :value
    def initialize value = Gene::UNDEFINED
      super(Expandable)

      set 'value', value
    end
  end

  class Array < ::Array
  end

  class Hash < ::Hash
  end

  # === SELF HOSTING ===
  # FunctionClass = Class.new 'Function', Block.new(nil, nil)
  # FunctionClass.prop 'name'
  # FunctionClass.prop 'arguments'
  # FunctionClass.prop 'block'
  # init = FunctionClass.new
  # init.name       = 'init'
  # init.arguments  = ['name']
  # init.statements = [
  #   (let @name name)
  #   Gene::Types::Base.new(Gene::Types::Symbol.new('let'), Gene::Types::Symbol.new('@name'), Gene::Types::Symbol.new('name'))
  # ]
  # FunctionClass.method 'init', call
  # call = FunctionClass.new
  # call.name       = 'call'
  # call.arguments  = []
  # call.statements = []
  # FunctionClass.method 'call', call

end
