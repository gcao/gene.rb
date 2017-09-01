module Gene::Macro
  class Ignore
    def to_s
      self.class.to_s
    end
  end
  IGNORE = Ignore.new

  class Function
    attr_reader :name, :arguments, :statements

    def initialize name, parent_scope, arguments, statements
      @name, @parent_scope, @arguments, @statements = name, parent_scope, arguments, statements
    end

    def call context, arg_values
      begin
        # Open new scope
        scope = Scope.new @parent_scope
        context.start_scope scope

        translate_arguments_as_local_variables scope, arg_values

        # Execute statements
        # Return result of last statement
        result = Gene::UNDEFINED
        statements.each do |stmt|
          result = context.process_internal stmt
          if result.is_a? ReturnValue
            result = result.value
            break
          end
        end
        result
      ensure
        # Ensure scope is closed
        context.end_scope scope
      end
    end

    private

    def translate_arguments_as_local_variables scope, arg_values
      # Add arguments/values to scope
      arg_values.each_with_index do |value, i|
        name = self.arguments[i]
        if name
          scope[name] = value
        end
      end
    end
  end

  # Created for iterators, e.g.
  # (#each array #do ...)
  # An anonymous function is created with implicit arguments: $_index, $_value
  class AnonymousFunction < Function
    def initialize arguments, statements
      super '', arguments, statements
    end
  end

  class Scope < Hash
    attr_reader :parent

    def initialize parent
      @parent = parent
      @auto_variables = {}
    end

    def [] name
      if has_key? name
        super name
      elsif parent
        parent[name]
      end
    end

    def let name, value
      if has_key?(name) or parent.nil?
        self[name] = value
      elsif parent
        parent.let name, value
      end
    end
  end

  class ReturnValue
    attr_reader :value

    def initialize value
      @value = value
    end

    def to_s
      "(#return #{@value.inspect})"
    end
    alias inspect to_s
  end

  class YieldValue
    attr_reader :value

    def initialize value
      @value = value
    end

    def to_s
      "(#yield #{@value.inspect})"
    end
    alias inspect to_s
  end

  class YieldValues
    attr_reader :values

    def initialize values = []
      @values = values
    end

    def empty?
      @values.empty?
    end

    def to_s
      "(#yield #{@values.map(&:inspect).join(' ')})"
    end
    alias inspect to_s
  end
end
