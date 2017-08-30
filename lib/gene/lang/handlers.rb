module Gene::Lang::Handlers
  %W(
    CLASS PROP METHOD NEW INIT CAST
    FN FNX
    CALL
    DEF LET
    IF
    FOR
  ).each do |name|
    const_set name, Gene::Types::Ident.new("#{name.downcase.gsub('_', '-')}")
  end

  CONTEXT   = Gene::Types::Ident.new('_context')
  SCOPE     = Gene::Types::Ident.new('_scope')
  INVOKE    = Gene::Types::Ident.new('_invoke')
  SELF      = Gene::Types::Ident.new('_self')

  # Handle scope variables, instance variables like @var and literals
  class DefaultHandler
    def call context, data
      if data.is_a? Gene::Types::Base
        if INVOKE === data
          target = context.process data.data[0]
          method = data.data[1].to_s
          args   = data.data[2..-1].to_a.map {|item| context.process(item) }
          target.send method, *args
        else
          Gene::NOT_HANDLED
        end
      elsif data == CONTEXT
        context
      elsif data == SCOPE
        context.scope
      elsif data == SELF
        context.self
      elsif data.is_a? Gene::Types::Ident
        if data.to_s[0] == '@'
          # instance variable
          context.self[data.to_s[1..-1]]
        else
          # scope variable
          context[data.name]
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
      name  = data.data.shift.to_s
      klass = Gene::Lang::Class.new name, data.data
      klass.call context: context
      context.global_scope[name] = klass
      klass
    end
  end

  class FunctionHandler
    def call context, data
      return Gene::NOT_HANDLED unless FN === data or FNX === data

      if FN === data
        name = data.data.shift.to_s
        fn   = Gene::Lang::Function.new name
        context.scope[name] = fn
      else
        name = 'anonymous'
        fn   = Gene::Lang::Function.new name
      end

      fn.parent_scope = context.scope

      fn.arguments = [data.data.shift].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.statements = data.data

      fn
    end
  end

  class MethodHandler
    def call context, data
      return Gene::NOT_HANDLED unless METHOD === data
      name = data.data[0].to_s
      fn = Gene::Lang::Function.new name
      fn.arguments = [data.data[1]].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.statements = data.data[2..-1]
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
      # Default code: [@x]  assume x is the property name
      code = data['get'] || [Gene::Types::Ident.new("@#{name}")]
      get.arguments = []
      get.statements = code
      context.self.instance_methods[get.name] = get

      set = Gene::Lang::Function.new "#{name}="
      # Default code: [value (let @x value)]  assume x is the property name
      code = data['set'] || [
        Gene::Types::Ident.new("value"),
        Gene::Types::Base.new(LET, Gene::Types::Ident.new("@#{name}"), Gene::Types::Ident.new("value"))
      ]
      arg_name  = code.shift.to_s
      set.arguments = [Gene::Lang::Argument.new(0, arg_name)]
      set.statements = code
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

  class CallHandler
    def call context, data
      return Gene::NOT_HANDLED unless CALL === data
      function = context.process data.data.shift
      self_object = context.process data.data.shift
      function.call context: context, self: self_object, arguments: data.data
    end
  end

  class CastHandler
    def call context, data
      return Gene::NOT_HANDLED unless CAST === data
      object = context.process(data.data[0])
      klass  = context.process(data.data[1])
      object.as klass
    end
  end

  class InitHandler
    def call context, data
      return Gene::NOT_HANDLED unless INIT === data
      name = INIT.name
      fn = Gene::Lang::Function.new name
      fn.arguments = [data.data[0]].flatten
        .select {|item| not item.nil? }
        .map.with_index {|item, i| Gene::Lang::Argument.new(i, item.name) }
      fn.statements = data.data[1..-1]
      context.self.instance_methods[INIT.name] = fn
      fn
    end
  end

  class DefHandler
    def call context, data
      return Gene::NOT_HANDLED unless DEF === data
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

  class LetHandler
    def call context, data
      return Gene::NOT_HANDLED unless LET === data
      name  = data.data[0].to_s
      value = context.process data.data[1]
      if name[0] == '@'
        context.self.set name[1..-1], value
      else
        context.scope.let name, value
      end
      Gene::Lang::Variable.new name, value
    end
  end

  class InvocationHandler
    def call context, data
      if data.is_a? Gene::Types::Base and data.data[0].is_a? Gene::Types::Ident and data.data[0].to_s[0] == '.'
        value = context.process data.type
        klass = get_class(value, context)
        method = klass.instance_methods[data.data[0].to_s[1..-1]]
        method.call context: context, self: value, arguments: data.data[1..-1].map{|item| context.process item}
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Types::Ident and data.type.name =~ /^[a-zA-Z_]/
        value = context.process(data.type)
        value.call context: context, arguments: data.data.map{|item| context.process item}
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Types::Ident and data.type.name =~ /^.(.*)$/
        klass = get_class(context.self, context)
        value = klass.instance_methods[$1]
        value.call context: context, self: context.self, arguments: data.data.map{|item| context.process item}
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Types::Base
        data.type = context.process data.type
        context.process data
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Lang::Function
        data.type.call context: context, arguments: data.data.map{|item| context.process item}
      else
        Gene::NOT_HANDLED
      end
    end

    private
    def get_class obj, context
      if obj.is_a? Array
        context["Array"]
      else
        obj.class
      end
    end
  end

  class BinaryExprHandler
    BINARY_OPERATORS = [
      Gene::Types::Ident.new('>'),
      Gene::Types::Ident.new('>='),
      Gene::Types::Ident.new('<'),
      Gene::Types::Ident.new('<='),

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
      when '<'  then left < right
      when '<=' then left <= right
      when '>'  then left > right
      when '>=' then left >= right

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
        context.process_statements true_logic
      else
        context.process_statements false_logic
      end
    end
  end

  class ForHandler
    def call context, data
      return Gene::NOT_HANDLED unless FOR === data
      # initialize
      context.process data.data.shift

      condition = data.data.shift
      update    = data.data.shift
      while context.process(condition)
        context.process_statements data.data
        context.process update
      end
    end
  end

end
