module Gene::Lang
  # All objects other than literals have this structure
  # type: a short Ident to help identify type of the object
  # attributes: Hash
  #   ...
  # data: literal or array or anything else
  #
  # type is stored in attributes with key '#type'
  # data is stored in attributes with key '#data'
  # class is stored in attributes with key '#class'
  class Object
    attr_reader :attributes

    def initialize klass = Object
      @attributes = {}
      @attributes["#class"] = klass
    end

    def class
      @attributes["#class"]
    end

    def class= klass
      @attributes["#class"] = klass
    end

    def get name
      @attributes[name]
    end
    alias [] get

    def set name, value
      @attributes[name] = value
    end
    alias []= set

    def as klass
      obj = Object.new klass
      @attributes.each do |key, value|
        obj[key] = value
      end
      obj["#class"] = klass
      obj
    end

    def self.attr_reader *names
      names.each do |name|
        name = name.to_s
        define_method(name) do
          @attributes[name.to_s]
        end
      end
    end

    def self.attr_accessor *names
      names.each do |name|
        name = name.to_s
        define_method(name) do
          @attributes[name]
        end
        define_method("#{name}=") do |value|
          @attributes[name] = value
        end
      end
    end
  end

  class Class < Object
    attr_accessor :name, :instance_methods, :properties
    def initialize name
      super(Class)

      set 'name', name
      set 'instance_methods', {}
      set 'properties', {}
    end

    def prop name
      instance_methods[name.to_s]  = Block.new [], [Gene::Types::Ident.new("@#{name}")]
      instance_methods["#{name}="] = Block.new ['value'], [
        Gene::Types::Base.new(
          Gene::Types::Ident.new('let'),
          Gene::Types::Ident.new("@#{name}"),
          Gene::Types::Ident.new('value'),
        )
      ]
    end

    def method name, function
      instance_methods[name.to_s] = function
    end
  end

  class Function < Object
    attr_reader :name
    attr_accessor :parent_scope, :arguments, :statements
    def initialize name
      super(Function)

      set 'name', name
    end

    def call options = {}
      scope = Scope.new parent_scope
      scope.arguments = arguments
      scope.set_variable '$arguments', options[:arguments]
      scope.update_arguments options[:arguments]
      context = options[:context]
      context.start_self options[:self]
      context.start_scope scope
      begin
        result = context.process_statements statements
        if result.is_a? ReturnValue
          result = result.value
        end
        result
      ensure
        context.end_scope
        context.end_self
      end
    end
  end

  class Property < Object
    attr_reader :name, :type, :getter, :setter
    def initialize name
      super(Property)

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
      if self.variables.keys.include? name
        self.variables[name] = value
      elsif self.parent and self.parent.defined?(name)
        self.parent.let name, value
      else
        self.variables[name] = value
      end
    end

    def update_arguments values
      if values and values.size > 0
        values.each.with_index do |value, index|
          argument = self.arguments.find {|arg| arg.index == index }
          self.set_variable(argument.name, value) if argument
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
  #   Gene::Types::Base.new(Gene::Types::Ident.new('let'), Gene::Types::Ident.new('@name'), Gene::Types::Ident.new('name'))
  # ]
  # FunctionClass.method 'init', call
  # call = FunctionClass.new
  # call.name       = 'call'
  # call.arguments  = []
  # call.statements = []
  # FunctionClass.method 'call', call

end
