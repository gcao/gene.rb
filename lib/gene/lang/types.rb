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
  end

  # TODO: change to single inheritance and include modules like Ruby
  class Class < Object
    attr_accessor :name, :methods, :prop_descriptors, :parent_classes, :modules
    def initialize name
      super(Class)

      set 'name', name
      set 'methods', {}
      set 'prop_descriptors', {}
      set 'parent_classes', []
      set 'modules', []
    end

    # def def_property name
    #   methods[name.to_s]  = Block.new [], [Gene::Types::Symbol.new("@#{name}")]
    #   methods["#{name}="] = Block.new ['value'], [
    #     Gene::Types::Base.new(
    #       Gene::Types::Symbol.new('let'),
    #       Gene::Types::Symbol.new("@#{name}"),
    #       Gene::Types::Symbol.new('value'),
    #     )
    #   ]
    # end

    # def define_method name, function
    #   methods[name.to_s] = function
    # end

    def method name
      methods[name] or super_method(name)
    end

    def super_method name
      parent_classes.reverse.each do |klass|
        method = klass.method(name)
        return method if method
      end

      nil
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

      scope.set_variable '$function', self
      scope.set_variable '$caller-context', context
      scope.arguments = self.arguments

      expanded_arguments = expand_arguments(options[:arguments])
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

    def expand_arguments arguments
      result = []

      arguments.each do |arg|
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
