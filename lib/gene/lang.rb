module Gene::Lang
  class Object
    def initialize klass
      @_class = klass
    end

    def class
      @_class
    end
  end

  class Class
    attr_reader :name, :block, :methods
    def initialize name, block
      @name, @block = name, block
      @methods = {}
    end

    def call options = {}
      options[:self] = self
      @block.call options
    end
  end

  class Function
    attr_reader :name, :block
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
      context.start_scope scope
      begin
        result = @block.call options
      ensure
        context.end_scope
      end
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
      variables[name]
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

    def [] name
      @statements[name]
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
end
