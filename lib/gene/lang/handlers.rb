module Gene::Lang::Handlers
  # Handle scope variables, instance variables like @var and literals
  class DefaultHandler
    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED if data.is_a? Gene::Types::Base
      if data.is_a? Gene::Types::Ident
        if data.to_s[0] == '@'
          # instance variable
          context.self[data.to_s[1..-1]]
        else
          # scope variable
          context.scope[data.name]
        end
      else
        # literals
        data
      end
    end
  end

  class ClassHandler
    CLASS = Gene::Types::Ident.new('class')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless CLASS.first_of_group? data
      name  = data.data[0].to_s
      stmts = data.data[1..-1]
      block = Gene::Lang::Block.new nil, stmts
      klass = Gene::Lang::Class.new name, block
      klass.call context: context
      context.scope[name] = klass
      klass
    end
  end

  class FunctionHandler
    FUNCTION = Gene::Types::Ident.new('fn')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless FUNCTION.first_of_group? data
      name = data.data[0].to_s
      fn = Gene::Lang::Function.new name
      arguments = [data.data[1]].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.block = Gene::Lang::Block.new arguments, data.data[2..-1]
      fn.inherit_scope = data.attributes['inherit_scope']
      context.scope[name] = fn
      fn
    end
  end

  class MethodHandler
    METHOD = Gene::Types::Ident.new('method')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless METHOD.first_of_group? data
      name = data.data[0].to_s
      fn = Gene::Lang::Function.new name
      arguments = [data.data[1]].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.block = Gene::Lang::Block.new arguments, data.data[2..-1]
      context.self.instance_methods[name] = fn
      fn
    end
  end

  class NewHandler
    NEW = Gene::Types::Ident.new('new')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless NEW.first_of_group? data
      klass = context.process(data.data[0])
      instance = Gene::Lang::Object.new klass
      if init = klass.instance_methods['init']
        init.call context: context, self: instance, arguments: data.data[1..-1]
      end
      instance
    end
  end

  class InitHandler
    INIT = Gene::Types::Ident.new('init')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless INIT.first_of_group? data
      name = INIT.name
      fn = Gene::Lang::Function.new name
      arguments = [data.data[0]].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.block = Gene::Lang::Block.new arguments, data.data[1..-1]
      context.self.instance_methods[INIT.name] = fn
      fn
    end
  end

  class LetHandler
    LET = Gene::Types::Ident.new('let')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless LET.first_of_group? data
      name  = data.data[0].to_s
      value = context.process data.data[1]
      if name[0] == '@'
        context.self.set name[1..-1], value
      else
        context.scope.set name, value
      end
      Gene::Lang::Variable.new name, value
    end
  end

  class InvocationHandler
    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      # If first is an ident that starts with [a-zA-Z]
      #   treat as a variable (pointing to function or value)
      # If there are two or more elements in the group,
      #   treat as invocation
      # If the second element is !,
      #   treat as invocation with no argument
      return Gene::NOT_HANDLED unless
        data.is_a? Gene::Types::Base and
        data.type.is_a? Gene::Types::Ident and
        data.type.name =~ /^[a-zA-Z]/

      name  = data.type.name
      value = context.scope[name]
      if data.data.size == 0
        value
      elsif data.data[0] == Gene::Types::Ident.new('!')
        value.call context: context
      elsif data.data[0].is_a? Gene::Types::Ident and data.data[0].to_s[0] == '.'
        klass = value.class
        method = klass.instance_methods[data.data[0].to_s[1..-1]]
        method.call context: context, self: value, arguments: data.data[1..-1]
      else
        value.call context: context, arguments: data.data
      end
    end
  end

  class BinaryExprHandler
    BINARY_OPERATORS = [
      Gene::Types::Ident.new('+'),
      Gene::Types::Ident.new('-'),
      Gene::Types::Ident.new('*'),
      Gene::Types::Ident.new('/'),
    ]

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and BINARY_OPERATORS.include?(data.data[0])

      op    = data.data[0].name
      left  = context.process(data.type)
      right = context.process(data.data[1])
      case op
      when '+' then left + right
      when '-' then left - right
      when '*' then left * right
      when '/' then left / right
      end
    end
  end

  # If statement can look like any of below
  # (if cond true_logic) - 3 elements
  # (if cond true_logic false_logic) - 4 elements
  # (if cond true_logic cond2 true_logic) - 5 elements
  # (if cond true_logic cond2 true_logic else_logic) - 6 elements
  # Same as (if cond true_logic (if cond2 true_logic else_logic))
  class IfHandler
    IF = Gene::Types::Ident.new('if')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless IF.first_of_group? data

      # data[1] is the condition
      # data[2] is an array of code to be run when the condition evaluates to true
      # data[3] is an array of code to be run when the condition evaluates to false
      condition   = data.data[0]
      true_logic  = data.data[1]
      false_logic = data.data[2]
      if context.process condition
        if true_logic.is_a? Array
          code = Gene::Lang::Block.new([], true_logic)
          code.call context: context
        else
          context.process(true_logic)
        end
      else
        if false_logic.is_a? Array
          code = Gene::Lang::Block.new([], false_logic)
          code.call context: context
        else
          context.process(false_logic)
        end
      end
    end
  end

end
