module Gene::Handlers::Lang
  # Handle scope variables, instance variables like @var and literals
  class DefaultHandler
    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED if data.is_a? Gene::Types::Group
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
      name  = data.second.to_s
      stmts = data[2..-1]
      block = Gene::Lang::Block.new nil, stmts
      klass = Gene::Lang::Class.new name, block
      klass.call context: context
      context.scope[name] = klass
      klass
    end
  end

  class Gene::Handlers::Lang::FunctionHandler
    FUNCTION = Gene::Types::Ident.new('fn')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless FUNCTION.first_of_group? data
      name = data.second.to_s
      fn = Gene::Lang::Function.new name
      arguments = [data.third].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.block = Gene::Lang::Block.new arguments, data[3..-1]
      fn.inherit_scope = data.metadata['inherit_scope']
      context.scope[name] = fn
      fn
    end
  end

  class Gene::Handlers::Lang::MethodHandler
    METHOD = Gene::Types::Ident.new('method')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      return Gene::NOT_HANDLED unless METHOD.first_of_group? data
      name = data.second.to_s
      fn = Gene::Lang::Function.new name
      arguments = [data.third].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.block = Gene::Lang::Block.new arguments, data[3..-1]
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
      klass = context.process(data.second)
      instance = Gene::Lang::Object.new klass
      if init = klass.instance_methods['init']
        init.call context: context, self: instance, arguments: data[2..-1]
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
      arguments = [data.second].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.block = Gene::Lang::Block.new arguments, data[2..-1]
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
      name  = data[1].to_s
      value = context.process data[2]
      if name[0] == '@'
        context.self.set name[1..-1], value
      else
        context.scope.set name, value
      end
      Gene::Lang::Variable.new name, value
    end
  end

  class Gene::Handlers::Lang::InvocationHandler
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
        data.is_a? Gene::Types::Group and
        data.first.is_a? Gene::Types::Ident and
        data.first.name =~ /^[a-zA-Z]/

      name  = data.first.name
      value = context.scope[name]
      if data.size == 1
        value
      elsif data.second == Gene::Types::Ident.new('!')
        value.call context: context
      elsif data.second.is_a? Gene::Types::Ident and data.second.to_s[0] == '.'
        klass = value.class
        method = klass.instance_methods[data.second.to_s[1..-1]]
        method.call context: context, self: value, arguments: data[2..-1]
      else
        value.call context: context, arguments: data.rest
      end
    end
  end

  class Gene::Handlers::Lang::BinaryExprHandler
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
      return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group and BINARY_OPERATORS.include?(data.second)

      op    = data.second.name
      left  = context.process(data.first)
      right = context.process(data.third)
      case op
      when '+' then left + right
      when '-' then left - right
      when '*' then left * right
      when '/' then left / right
      end
    end
  end

end
