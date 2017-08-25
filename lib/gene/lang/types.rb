module Gene::Lang
  class Undefined
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
    alias_method :[], :get

    def set name, value
      @attributes[name] = value
    end
    alias_method :[]=, :set
  end

  class Class
    attr_reader :name, :instance_methods, :properties
    def initialize name, block
      @name, @block = name, block
      @instance_methods = {}
      @properties = {}
    end

    def call options = {}
      scope = Scope.new nil
      context = options[:context]
      context.start_self self
      context.start_scope scope
      begin
        @block.call options
      ensure
        context.end_scope
        context.end_self
      end
    end
  end

  class Function
    attr_reader :name, :block
    attr_accessor :inherit_scope
    def initialize name
      @name = name
    end

    def block= block
      @block = block
    end

    def call options = {}
      scope = Scope.new nil
      scope.arguments = @block.arguments
      scope.update_arguments options[:arguments]
      context = options[:context]
      context.start_self options[:self]
      context.start_scope scope
      begin
        @block.call options
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

    def get name
      value = variables[name]
      if value == nil and not variables.keys.include? name
        UNDEFINED
      else
        value
      end
    end
    alias_method :[], :get

    def set name, value
      variables[name] = value
    end
    alias_method :[]=, :set

    def update_arguments values
      if values and values.size > 0
        values.each.with_index do |value, index|
          argument = @arguments.find {|arg| arg.index == index }
          self[argument.name] = value if argument
        end
      end
    end
  end

  class Block
    attr_accessor :arguments, :statements
    def initialize arguments, statements
      @arguments  = arguments  || []
      @statements = statements || []
    end

    def [] index
      @statements[index]
    end

    def call options = {}
      result = nil
      statements.each do |stmt|
        result = options[:context].process stmt
      end
      result
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
end
