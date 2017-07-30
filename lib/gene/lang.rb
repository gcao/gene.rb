module Gene::Lang
  class Class
    attr_reader :name, :block
    def initialize name, block
      @name, @block = name, block
      call self
    end

    def call options
      @block.call options
      self
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

    def call options
      @block.call options
    end
  end

  class Scope
    attr_reader :parent, :variables
    def initialize parent
      @parent    = parent
      @variables = {}
    end

    def get name
      variables[name]
    end
    alias_method :[], :get

    def set name, value
      variables[name] = value
    end
    alias_method :[]=, :set
  end

  class Block
    attr_accessor :scope, :arguments, :statements
    def initialize arguments, statements
      @arguments  = arguments  || []
      @statements = statements || []
    end

    def [] name
      @statements[name]
    end

    def call options
      statements.each do |stmt|
        stmt.call options
      end
    end
  end

  class Argument
    attr_reader :name
    def initialize name
      @name = name
    end

    def == other
      other.is_a? self.class and @name == other.name
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
