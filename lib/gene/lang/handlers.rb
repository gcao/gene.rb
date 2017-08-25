module Gene::Lang::Handlers
  FUNCTION = Gene::Types::Ident.new('fn')
  %W(
    CLASS PROP METHOD NEW INIT
    LET
    IF
  ).each do |name|
    const_set name, Gene::Types::Ident.new("#{name.downcase.gsub('_', '-')}")
  end

  # Handle scope variables, instance variables like @var and literals
  class DefaultHandler
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
    def call context, data
      return Gene::NOT_HANDLED unless CLASS === data
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
    def call context, data
      return Gene::NOT_HANDLED unless FUNCTION === data
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
    def call context, data
      return Gene::NOT_HANDLED unless METHOD === data
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

  class PropertyHandler
    def call context, data
      return Gene::NOT_HANDLED unless PROP === data
      name = data.data[0].to_s
      prop = Gene::Lang::Property.new name
      context.self.properties[name] = prop

      get = Gene::Lang::Function.new name
      get.block = Gene::Lang::Block.new [], data['get']
      context.self.instance_methods[get.name] = get

      set = Gene::Lang::Function.new "#{name}="
      arg_name  = data['set'].shift.to_s
      arguments = [Gene::Lang::Argument.new(0, arg_name)]
      set.block = Gene::Lang::Block.new arguments, data['set']
      context.self.instance_methods[set.name] = set
      nil
    end
  end

  class NewHandler
    def call context, data
      return Gene::NOT_HANDLED unless NEW === data
      klass = context.process(data.data[0])
      instance = Gene::Lang::Object.new klass
      if init = klass.instance_methods['init']
        init.call context: context, self: instance, arguments: data.data[1..-1]
      end
      instance
    end
  end

  class InitHandler
    def call context, data
      return Gene::NOT_HANDLED unless INIT === data
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
    def call context, data
      return Gene::NOT_HANDLED unless LET === data
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
      # if data.data.size == 0
      #   value
      # elsif data.data[0] == Gene::Types::Ident.new('!')
      #   value.call context: context
      # elsif data.data[0].is_a? Gene::Types::Ident and data.data[0].to_s[0] == '.'
      if data.data[0].is_a? Gene::Types::Ident and data.data[0].to_s[0] == '.'
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
    def call context, data
      return Gene::NOT_HANDLED unless IF === data

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
