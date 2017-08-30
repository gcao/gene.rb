module Gene::Lang
  class Undefined
    def to_s
      'undefined'
    end
    alias inspect to_s
  end

  # All objects other than literals have this structure
  # type: a short Ident to help identify type of the object
  # attributes: Hash
  #   ...
  # data: literal or array or anything else
  class Object
    attr_reader :attributes
    def initialize klass
      @_class = klass
      @attributes = {}
    end

    def class
      @_class
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
      obj
    end
  end

  class Class
    attr_reader :name, :instance_methods, :properties
    def initialize name, statements
      @name, @statements = name, statements
      @instance_methods = {}
      @properties = {}
    end

    def prop name
      @instance_methods[name.to_s]  = Block.new [], [Gene::Types::Ident.new("@#{name}")]
      @instance_methods["#{name}="] = Block.new ['value'], [
        Gene::Types::Base.new(
          Gene::Types::Ident.new('let'),
          Gene::Types::Ident.new("@#{name}"),
          Gene::Types::Ident.new('value'),
        )
      ]
    end

    def method name, function
      @instance_methods[name.to_s] = function
    end

    def call options = {}
      scope = Scope.new nil
      context = options[:context]
      context.start_self self
      context.start_scope scope
      begin
        context.process_statements @statements
        self
      ensure
        context.end_scope
        context.end_self
      end
    end
  end

  class Function
    attr_reader :name
    attr_accessor :parent_scope, :arguments, :statements
    def initialize name
      @name = name
    end

    def call options = {}
      scope = Scope.new @parent_scope
      scope.arguments = @arguments
      scope.set '_arguments', options[:arguments]
      scope.update_arguments options[:arguments]
      context = options[:context]
      context.start_self options[:self]
      context.start_scope scope
      begin
        context.process_statements @statements
      ensure
        context.end_scope
        context.end_self
      end
    end
  end

  class Property
    attr_reader :name, :type, :getter, :setter
    def initialize name
      @name = name
    end
  end

  class Scope
    attr_reader :parent, :variables
    attr_accessor :arguments
    def initialize parent
      @parent    = parent
      @variables = {}
      @arguments = []
    end

    def defined? name
      @variables.keys.include?(name) or (@parent and @parent.defined?(name))
    end

    def get name
      name = name.to_s
      if variables.keys.include? name
        variables[name]
      elsif @parent
        parent.get name
      else
        UNDEFINED
      end
    end
    alias [] get

    def set name, value
      variables[name] = value
    end
    alias []= set

    def let name, value
      if @variables.keys.include? name
        @variables[name] = value
      elsif @parent and @parent.defined?(name)
        @parent.let name, value
      else
        @variables[name] = value
      end
    end

    def update_arguments values
      if values and values.size > 0
        values.each.with_index do |value, index|
          argument = @arguments.find {|arg| arg.index == index }
          self[argument.name] = value if argument
        end
      end
    end
  end

  class Argument
    attr_reader :index, :name
    def initialize index, name
      @index, @name = index, name
    end

    def == other
      other.is_a? self.class and @index == other.index and @name == other.name
    end
  end

  class Assignment
    attr_reader :variable, :expression
    def initialize variable, expression = nil
      @variable, @expression = variable, expression
    end

    def call options
    end
  end

  class Variable
    attr_reader :name
    attr_accessor :value
    def initialize name, value = nil
      @name, @value = name, value
    end

    def call options
    end
  end

  UNDEFINED = Undefined.new
  NIL       = nil
  TRUE      = true
  FALSE     = false

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
