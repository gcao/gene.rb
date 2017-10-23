module Gene::Lang::Handlers
  %W(
    NS
    CLASS PROP METHOD NEW INIT CAST
    MODULE INCLUDE
    EXTEND SUPER
    SELF
    FN FNX FNXX
    RETURN
    CALL DO
    DEF
    BEFORE AFTER WHEN CONTINUE
    IMPORT EXPORT FROM
    PUBLIC PRIVATE
    IF IF_NOT
    FOR LOOP
    BREAK
    PRINT PRINTLN
    ASSERT DEBUG
    NOOP
  ).each do |name|
    const_set name, Gene::Types::Symbol.new("#{name.downcase.gsub('_', '-')}")
  end

  PLACEHOLDER = Gene::Types::Symbol.new('_')
  PROP_NAME   = Gene::Types::Symbol.new('@')
  APPLICATION = Gene::Types::Symbol.new('$application')
  CONTEXT     = Gene::Types::Symbol.new('$context')
  GLOBAL      = Gene::Types::Symbol.new('$global')
  SCOPE       = Gene::Types::Symbol.new('$scope')
  INVOKE      = Gene::Types::Symbol.new('$invoke')

  REPL        = Gene::Types::Symbol.new('open-repl')

  module Utilities
    def expand array
      i = 0
      while i < array.length
        item = array[i]
        if item.is_a? Gene::Lang::Expandable
          array.delete_at i
          item.value.each do |x|
            array.insert i, x
            i += 1
          end
        else
          i += 1
        end
      end
      array
    end
  end

  # Handle scope variables, instance variables like @var and literals
  class DefaultHandler
    include Utilities

    def call context, data
      if data.is_a? Gene::Types::Base
        if INVOKE === data
          target = context.process data.data[0]
          method = context.process(data.data[1]).to_s
          args   = data.data[2..-1].to_a.map {|item| context.process(item) }
          args   = expand args
          target.send method, *args
        elsif PROP_NAME === data
          Gene::Lang::PropertyName.new context.process(data.data[0])
        elsif DO === data
          context.process_statements data.data
        elsif RETURN === data
          Gene::Lang::ReturnValue.new context.process(data.data[0])
        elsif BREAK === data
          Gene::Lang::BreakValue.new context.process(data.data[0])
        elsif REPL === data
          repl = Gene::Lang::Repl.new context
          puts
          repl.start
        elsif data === DEBUG
          Gene::UNDEFINED
        elsif data.type.is_a? Gene::Lang::PropertyName
          context.self[data.type.name]
        else
          Gene::NOT_HANDLED
        end
      elsif data.is_a?(::Array) and not data.is_a?(Gene::Lang::Array)
        result = Gene::Lang::Array.new
        data.each do |item|
          result.push context.process(item)
        end
        result
      elsif data.is_a?(Hash) and not data.is_a?(Gene::Lang::Hash)
        result = Gene::Lang::Hash.new
        data.each do |key, value|
          result[key] = context.process value
        end
        result
      elsif data == PLACEHOLDER or data == NOOP
        Gene::UNDEFINED
      elsif data == BREAK
        Gene::Lang::BreakValue.new
      elsif data == RETURN
        Gene::Lang::ReturnValue.new
      elsif data == APPLICATION
        context.application
      elsif data == CONTEXT
        context
      elsif data == GLOBAL
        context.application.global_namespace
      elsif data == SCOPE
        context.scope
      elsif data == SELF
        context.self
      elsif data.is_a? Gene::Types::Symbol
        name = data.name
        if name =~ /^(.*)\.\.\.$/
          if $1[0] == '@'
            # property
            Gene::Lang::Expandable.new context.self[$1[1..-1]]
          else
            # scope variable
            Gene::Lang::Expandable.new context.get_member($1)
          end
        else
          if name[0] == '@'
            # property
            context.self[name[1..-1]]
          elsif name.include? '/'
            parts = name.split '/'
            ns = context.get_member(parts.shift)
            # TODO: add test case for nested namespaces and finish below logic
            # while parts.size > 1
            # end
            ns.members[parts.shift]
          else
            # scope variable
            context.get_member(name)
          end
        end
      else
        # literals
        data
      end
    end
  end

  class ModuleHandler
    def call context, data
      return Gene::NOT_HANDLED unless MODULE === data
      name  = data.data[0].to_s
      klass = Gene::Lang::Module.new name

      scope = Gene::Lang::Scope.new context.scope, false
      new_context = context.extend scope: scope, self: klass
      # TODO: check whether Object class is defined.
      # If yes, and the newly defined class isn't Object and doesn't have a parent class, set Object as its parent class
      new_context.process_statements data.data[1..-1] || []
      if data['global']
        context.set_global name, klass
      else
        context.define name, klass
      end
      klass
    end
  end

  class ClassHandler
    def call context, data
      return Gene::NOT_HANDLED unless CLASS === data
      name  = data.data[0].to_s
      klass = Gene::Lang::Class.new name

      scope = Gene::Lang::Scope.new nil, false
      new_context = context.extend scope: scope, self: klass
      # TODO: check whether Object class is defined.
      # If yes, and the newly defined class isn't Object and doesn't have a parent class, set Object as its parent class
      new_context.process_statements data.data[1..-1] || []
      if data['global']
        context.set_global name, klass
      else
        context.define name, klass
      end
      klass
    end
  end

  class FunctionHandler
    def call context, data
      return Gene::NOT_HANDLED unless FN === data or FNX === data or FNXX === data

      next_index = 0
      if FN === data
        name = data.data[next_index].to_s
        next_index += 1
        fn   = Gene::Lang::Function.new name
        # context.scope.set_member name, fn
        context.define name, fn
      else
        name = ''
        fn   = Gene::Lang::Function.new name
      end

      # inherit-scope defaults to true unless its value is set to false
      if data['inherit-scope'] == false
        fn.inherit_scope = false
      else
        fn.inherit_scope = true
        fn.parent_scope  = context.scope
      end

      # eval-arguments defaults to true unless its value is set to false
      if data['eval-arguments'] == false
        fn.eval_arguments = false
      else
        fn.eval_arguments = true
      end

      if not FNXX === data
        fn.args_matcher = Gene::Lang::Matcher.new
        fn.args_matcher.from_array data.data[next_index]

        next_index += 1
      end

      fn.statements = data.data[next_index..-1] || []

      fn
    end
  end

  class ExtendHandler
    def call context, data
      return Gene::NOT_HANDLED unless EXTEND === data

      klass = context.process data.data[0]
      # TODO: if the parent class is Object, replace it with klass
      context.self.parent_class = klass
      Gene::UNDEFINED
    end
  end

  class IncludeHandler
    def call context, data
      return Gene::NOT_HANDLED unless INCLUDE === data

      mod = context.process data.data[0]
      context.self.modules.push mod
      Gene::UNDEFINED
    end
  end

  class SuperHandler
    def call context, data
      return Gene::NOT_HANDLED unless SUPER === data

      # TODO: what do we do with arguments?
      # If there is arguments, then pass in, else re-use them
      method    = context.get_member('$method')
      args      = context.get_member('$arguments')
      hierarchy = context.get_member('$hierarchy')
      hierarchy.next.handle_method(
        context: context,
        method: method,
        hierarchy: hierarchy,
        arguments: args,
        self: context.self
      )
    end
  end

  class MethodHandler
    def call context, data
      return Gene::NOT_HANDLED unless METHOD === data
      name = data.data[0].to_s
      fn = Gene::Lang::Function.new name
      fn.args_matcher = Gene::Lang::Matcher.new
      fn.args_matcher.from_array data.data[1]
      fn.statements = data.data[2..-1]
      context.self.methods[name] = fn
      fn
    end
  end

  class PropHandler
    def call context, data
      return Gene::NOT_HANDLED unless PROP === data
      name = data.data[0].to_s
      prop = Gene::Lang::Property.new name
      context.self.properties[name] = prop

      get = Gene::Lang::Function.new name
      # Default code: [@x]  assume x is the property name
      code = data['get'] || [Gene::Types::Symbol.new("@#{name}")]
      get.args_matcher = Gene::Lang::Matcher.new
      get.args_matcher.from_array []
      get.statements = code
      context.self.methods[get.name] = get

      set = Gene::Lang::Function.new "#{name}="
      # Default code: [value (@x = value)]  assume x is the property name
      code = data['set'] || [
        Gene::Types::Symbol.new("value"),
        Gene::Types::Base.new(Gene::Types::Symbol.new("@#{name}"), Gene::Types::Symbol.new("="), Gene::Types::Symbol.new("value"))
      ]
      arg_name  = code[0].to_s
      set.args_matcher = Gene::Lang::Matcher.new
      set.args_matcher.from_array arg_name
      set.statements = code[1..-1] || []
      context.self.methods[set.name] = set
      nil
    end
  end

  class NewHandler
    def call context, data
      return Gene::NOT_HANDLED unless NEW === data
      klass = context.process(data.data[0])
      instance = Gene::Lang::Object.new klass
      if init = klass.methods[INIT.name]
        args = data.data[1..-1]
        args = Gene::Lang::Object.from_array(args)
        init.call context: context, self: instance, arguments: args
      end
      instance
    end
  end

  class CallHandler
    def call context, data
      return Gene::NOT_HANDLED unless CALL === data
      function = context.process data.data[0]
      self_object = context.process data.data[1]
      args = data.data[2..-1] || []
      args = Gene::Lang::Object.from_array(args)
      function.call context: context, self: self_object, arguments: args
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
      fn.args_matcher = Gene::Lang::Matcher.new
      fn.args_matcher.from_array data.data[0]
      fn.statements = data.data[1..-1]
      context.self.methods[INIT.name] = fn
      fn
    end
  end

  class DefHandler
    def call context, data
      return Gene::NOT_HANDLED unless DEF === data
      name  = data.data[0].to_s
      value = context.process data.data[1]
      if name[0] == '@'
        context.self.set_member name[1..-1], value
      else
        context.define name, value
      end
      Gene::Lang::Variable.new name, value
    end
  end

  class InvocationHandler
    include Utilities

    def call context, data
      if data.is_a? Gene::Types::Base and data.data[0].is_a? Gene::Types::Symbol and data.data[0].to_s[0] == '.'
        value = context.process data.type
        klass = get_class(value, context)
        hierarchy = Gene::Lang::HierarchySearch.new(klass.ancestors)
        method = data.data[0].to_s[1..-1]
        args = data.data[1..-1].map {|arg| context.process arg }
        args = Gene::Lang::Object.from_array(args)
        hierarchy.next.handle_method({
          hierarchy: hierarchy,
          method: method,
          context: context,
          arguments: args,
          self: value
        })
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Types::Symbol and data.type.name =~ /^[a-zA-Z_]/
        value = context.process(data.type)
        args = data.data
        if value.eval_arguments
          args = args.map{|item| context.process item}
        end
        args = expand args
        args = Gene::Lang::Object.from_array(args)
        value.call context: context, arguments: args
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Types::Symbol and data.type.name =~ /^.(.*)$/
        method = $1
        klass = get_class(context.self, context)
        hierarchy = Gene::Lang::HierarchySearch.new(klass.ancestors)
        args = data.data.map{|item| context.process item}
        args = expand args
        args = Gene::Lang::Object.from_array(args)
        hierarchy.next.handle_method(
          hierarchy: hierarchy,
          method: method,
          context: context,
          arguments: args,
          self: context.self
        )
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Types::Base
        data.type = context.process data.type
        context.process data
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Lang::Function
        args = data.data.map{|item| context.process item}
        args = expand args
        args = Gene::Lang::Object.from_array(args)
        data.type.call context: context, arguments: args
      else
        Gene::NOT_HANDLED
      end
    end

    private

    def get_class obj, context
      if obj.is_a? Array
        context.get_member("Array")
      elsif obj.is_a? Hash
        context.get_member("Hash")
      elsif obj.is_a? Fixnum
        context.get_member("Int")
      elsif obj.is_a? Gene::Lang::Class
        context.get_member("Class")
      elsif obj.class == Gene::Lang::Object
        context.get_member("Object")
      else
        obj.class
      end
    end
  end

  class AssignmentHandler
    ASSIGNMENT_OPERATORS = [
      Gene::Types::Symbol.new('='),
      Gene::Types::Symbol.new('+='),
      Gene::Types::Symbol.new('-='),
      Gene::Types::Symbol.new('*='),
      Gene::Types::Symbol.new('/='),
      Gene::Types::Symbol.new('&&='),
      Gene::Types::Symbol.new('||='),
    ]

    def call context, data
      return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and ASSIGNMENT_OPERATORS.include?(data.data[0])

      op    = data.data[0].name
      value = context.process(data.data[1])

      is_property = false

      if data.type.is_a? Gene::Types::Base
        name = context.process data.type
        if name.is_a? Gene::Lang::PropertyName
          name = name.name
          is_property = true
        end
      else
        name = data.type.to_s
        if name[0] == '@'
          name = name[1..-1]
          is_property = true
        end
      end

      if is_property
        old_value = context.self.get name
        value     = handle(op, old_value, value)
        context.self.set name, value
      else
        old_value = context.get_member(name)
        value     = handle(op, old_value, value)
        context.set_member name, value
      end

      value
    end

    def handle op, old_value, change_value
      case op
      when '='   then change_value
      when '+='  then old_value +  change_value
      when '-='  then old_value -  change_value
      when '*='  then old_value *  change_value
      when '/='  then old_value /  change_value
      when '&&=' then old_value && change_value
      when '||=' then old_value || value
      else raise "Invalid operator #{op.inspect}"
      end
    end
  end

  class AspectHandler
    def call context, data
      return Gene::NOT_HANDLED unless BEFORE === data or AFTER === data or WHEN === data

      aspect = Gene::Lang::Aspect.new data.type.to_s
      aspect.method_matcher = data.data[0]
      aspect.args_matcher = data.data[1]
      aspect.logic = data.data[2..-1]

      if BEFORE === data
        context.self.before_aspects << aspect
      elsif AFTER === data
        context.self.after_aspects << aspect
      else
        context.self.when_aspects << aspect
      end
    end
  end

  class ContinueHandler
    def call context, data
      return Gene::NOT_HANDLED unless CONTINUE === data

      method    = context.get_member('$method')
      args      = context.get_member('$arguments')
      hierarchy = context.get_member('$hierarchy')
      aspects   = context.get_member('$aspects')
      hierarchy.current.handle_method(
        context: context,
        method: method,
        hierarchy: hierarchy,
        arguments: args,
        aspects: aspects,
        self: context.self
      )
    end
  end

  class BinaryExprHandler
    BINARY_OPERATORS = [
      Gene::Types::Symbol.new('=='),
      Gene::Types::Symbol.new('!='),
      Gene::Types::Symbol.new('>'),
      Gene::Types::Symbol.new('>='),
      Gene::Types::Symbol.new('<'),
      Gene::Types::Symbol.new('<='),

      Gene::Types::Symbol.new('+'),
      Gene::Types::Symbol.new('-'),
      Gene::Types::Symbol.new('*'),
      Gene::Types::Symbol.new('/'),

      Gene::Types::Symbol.new('&&'),
      Gene::Types::Symbol.new('||'),
    ]

    def call context, data
      return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and BINARY_OPERATORS.include?(data.data[0])

      op    = data.data[0].name
      left  = context.process(data.type)
      right = context.process(data.data[1])
      case op
      when '==' then left == right
      when '!=' then left != right
      when '<'  then left < right
      when '<=' then left <= right
      when '>'  then left > right
      when '>=' then left >= right

      when '+' then left + right
      when '-' then left - right
      when '*' then left * right
      when '/' then left / right

      when '&&' then left && right
      when '||' then left || right
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
      return Gene::NOT_HANDLED unless IF === data or IF_NOT === data

      condition   = data.data[0]
      true_logic  = data.data[1]
      false_logic = data.data[2]
      if context.process condition
        logic = IF === data ? true_logic : false_logic
      else
        logic = IF === data ? false_logic : true_logic
      end
      context.process logic
    end
  end

  class ForHandler
    def call context, data
      return Gene::NOT_HANDLED unless FOR === data
      # initialize
      context.process data.data[0]

      condition = data.data[1]
      update    = data.data[2]
      # (for _ _ _ ...) is same as (loop ...)
      # _ is treated as true in place of condition
      while condition == PLACEHOLDER ||
            ((value = context.process(condition)) && value != Gene::UNDEFINED)
        # TODO: add tests for next, break and return
        result = context.process_statements data.data[3..-1] || []
        if result.is_a? Gene::Lang::ReturnValue
          return result
        elsif result.is_a? Gene::Lang::BreakValue
          break
        end
        context.process update
      end

      # TODO: for loop should return last value from the inside, NOT what the condition evaluates to
      Gene::UNDEFINED
    end
  end

  class LoopHandler
    def call context, data
      return Gene::NOT_HANDLED unless LOOP === data

      while true do
        result = context.process_statements data.data
        if result.is_a? Gene::Lang::BreakValue
          break result.value
        elsif result.is_a? Gene::Lang::ReturnValue
          break result
        end
      end
    end
  end

  class NamespaceHandler
    def call context, data
      return Gene::NOT_HANDLED unless NS === data

      name = data.data[0].to_s
      ns   = Gene::Lang::Namespace.new name, context.scope
      context.define name, ns

      new_context             = Gene::Lang::Context.new
      new_context.application = context.application
      new_context.self        = ns
      new_context.namespace   = ns
      new_context.process data.data[1..-1]
    end
  end

  class ImportHandler
    def call context, data
      return Gene::NOT_HANDLED unless IMPORT === data

      raise "Invalid import statement: #{data}" if data.data.length <= 2 or data.data[-2] != FROM

      file = data.data.last.to_s
      file += '.gene' unless file =~ /\.gene$/
      # Parse file, which should return a namespace object
      new_context = context.application.create_root_context
      interpreter = Gene::Lang::Interpreter.new new_context
      interpreter.parse_and_process File.read(context.get_member('__DIR__') + '/' + file)

      ns = new_context.self

      data.data[0..-3].each do |item|
        name = item.to_s
        if ns.defined? name
          if ns.get_access_level(name) == 'private'
            raise "#{name} is not public."
          end
        else
          raise "#{name} is not defined."
        end
        context.define name, new_context.get_member(name)
      end

      Gene::UNDEFINED
    end
  end

  class AccessLevelHandler
    def call context, data
      return Gene::NOT_HANDLED unless PUBLIC === data or PRIVATE === data

      raise "This statement is only supported inside a namespace: #{data}" unless context.self.is_a? Gene::Lang::Namespace

      data.data.each do |item|
        context.self.set_access_level item.to_s, data.type.to_s
      end
    end
  end

  class PrintHandler
    def call context, data
      return Gene::NOT_HANDLED unless PRINT === data or PRINTLN === data

      data.data.each do |item|
        print context.process item
        print "\n" if PRINTLN === data
      end
    end
  end

  class AssertHandler
    def call context, data
      return Gene::NOT_HANDLED unless ASSERT === data

      expr = data.data[0]
      if not context.process(expr)
        message = context.process data.data[1]
        error  = "Assertion failure: "
        error << message.to_s << ": " if message
        error << expr.to_s
        raise error
      end
    end
  end

  class CatchAllHandler
    def call context, data
      raise "Should not reach here: input=#{data.inspect}"
    end
  end
end
