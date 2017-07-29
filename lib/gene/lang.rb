module Gene::Lang
  class Class
    attr_reader :name, :block
    def initialize name, block = Block.new
      @name, @block = name, block
      call self
    end

    def call context = nil
      @block.call context
      self
    end
  end

  class Function
    attr_reader :name, :args, :block
    def initialize name, args, block = Block.new
      @name, @args, @block = name, args, block
    end

    def call context = nil
      self
    end
  end

  class Block < Array
    def initialize statements = []
      super statements
    end

    def call context = nil
      each do |stmt|
        stmt.call context
      end
    end
  end

  class Argument
    attr_reader :name
    def initialize name
      @name = name
    end

    def call context = nil
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

    def call context = nil
    end
  end

  class Variable
    attr_reader :name
    attr_accessor :value
    def initialize name, value = nil
      @name, @value = name, value
    end

    def call context = nil
    end
  end
end
