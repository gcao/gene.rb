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
      @klass = klass
      # @properties["#class"] = klass
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
      method_name = options[:method]
      args        = options[:arguments]
      _self       = options[:self]
      _self.send method_name, *args
    end
  end

  class Application < Object
    attr_accessor :global_scope, :root_context, :interpreter_options
    def initialize
      super(Application)

      set 'global_scope', Gene::Lang::Scope.new(nil)

      context = Context.new
      context.application = self
      context.scope = Gene::Lang::Scope.new(nil)
      set 'root_context', context
    end
  end

  class Context < Object
    attr_accessor :scope, :self
    def initialize
      super(Context)
    end

    def extend scope, _self
      new_context = Context.new
      new_context.application = @application
      new_context.scope = scope
      new_context.self = _self
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

    def global_scope
      application.global_scope
    end

    # def start_scope scope = Gene::Lang::Scope.new(nil)
    #   scopes.push scope
    # end

    # def end_scope
    #   throw "Scope error: can not close the root scope." if scopes.size == 0
    #   scopes.pop
    # end

    # def self
    #   self_objects.last
    # end

    # def start_self self_object
    #   self_objects.push self_object
    # end

    # def end_self
    #   self_objects.pop
    # end

    def get name
      if scope.defined? name
        scope.get_variable name
      else
        global_scope.get_variable name
      end
    end
    alias [] get

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
        @ancestors.push mod
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
    attr_accessor :parent_scope, :arguments, :statements
    attr_accessor :inherit_scope, :eval_arguments
    def initialize name
      super(Function)

      set 'name', name
      self.inherit_scope = true # Default inherit_scope to true
      self.eval_arguments = true # Default inherit_scope to true
    end

    def call options = {}
      _parent_scope = inherit_scope ? parent_scope : nil
      scope = Scope.new _parent_scope
      context = options[:context]

      scope.set_variable '$method', options[:method] if options[:method]
      scope.set_variable '$hierarchy', options[:hierarchy] if options[:hierarchy]

      scope.set_variable '$function', self
      scope.set_variable '$caller-context', context
      scope.arguments = self.arguments

      expanded_arguments = expand_arguments(context, options[:arguments])
      scope.set_variable '$arguments', expanded_arguments
      scope.update_arguments expanded_arguments

      new_context = context.extend scope, options[:self]
      result = new_context.process_statements statements
      if result.is_a? ReturnValue
        result = result.value
      end
      result
    end

    private

    def expand_arguments context, arguments
      result = []

      arguments.each do |arg|
        arg = context.process arg
        if arg.is_a? Expandable
          arg.value.each do |value|
            result << value
          end
        else
          result << arg
        end
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
    attr_accessor :parent, :variables, :arguments
    def initialize parent
      super(Scope)

      set 'parent', parent
      set 'variables', {}
      set 'arguments', []
    end

    def defined? name
      self.variables.keys.include?(name) or (self.parent and self.parent.defined?(name))
    end

    def get_variable name
      name = name.to_s
      raise "#{name} is not defined." unless self.defined? name

      if self.variables.keys.include? name
        self.variables[name]
      elsif self.parent
        self.parent.get_variable name
      else
        Gene::UNDEFINED
      end
    end

    def set_variable name, value
      self.variables[name] = value
    end

    def let name, value
      raise "#{name} is not defined." unless self.defined? name

      if self.variables.keys.include? name
        self.variables[name] = value
      elsif self.parent and self.parent.defined?(name)
        self.parent.let name, value
      else
        self.variables[name] = value
      end
    end

    def update_arguments values
      return if not self.arguments

      value_index = 0
      self.arguments.each_with_index do |arg|
        if arg.name =~ /^(.*)\.\.\.$/
          set_variable $1, values[value_index..-1] || []
        else
          set_variable arg.name, values[value_index]
          value_index += 1
        end
      end
    end
  end

  class Argument < Object
    attr_reader :index, :name
    def initialize index, name
      super(Argument)

      set 'index', index
      set 'name', name
    end

    def == other
      other.is_a? self.class and @index == other.index and @name == other.name
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

  class Namespace < Object
    attr_reader :name, :members
    def initialize name
      super(Namespace)

      set 'name', name
      set 'members', {}
    end
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
