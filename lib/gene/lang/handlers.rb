module Gene::Lang::Handlers
  %W(
    NS
    CLASS PROP METHOD NEW INIT CAST
    MODULE INCLUDE
    EXTEND SUPER
    SELF WITH
    SCOPE
    FN FNX FNXX BIND
    RETURN
    MATCH
    CALL DO
    VAR NSVAR
    EXPAND
    ASPECT BEFORE AFTER WHEN CONTINUE
    IMPORT EXPORT FROM
    PUBLIC PRIVATE
    IF IF_NOT ELSE_IF ELSE THEN
    FOR LOOP
    THROW CATCH
    BREAK
    RENDER
    EVAL
    PRINT PRINTLN
    ASSERT DEBUG
    NOOP
  ).each do |name|
    const_set name, Gene::Types::Symbol.new("#{name.downcase}")
  end

  PLACEHOLDER = Gene::Types::Symbol.new('_')
  NOT         = Gene::Types::Symbol.new('!')
  PROP_NAME   = Gene::Types::Symbol.new('@')
  APPLICATION = Gene::Types::Symbol.new('$application')
  CONTEXT     = Gene::Types::Symbol.new('$context')
  GLOBAL      = Gene::Types::Symbol.new('$global')
  CURRENT_SCOPE = Gene::Types::Symbol.new('$scope')
  INVOKE      = Gene::Types::Symbol.new('$invoke')

  REPL        = Gene::Types::Symbol.new('open_repl')

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

    def to_str obj, context
      klass     = get_class obj, context
      hierarchy = Gene::Lang::HierarchySearch.new(klass.ancestors)
      method    = 'to_s'
      args      = []
      return hierarchy.next.handle_method({
        hierarchy: hierarchy,
        method: method,
        context: context,
        arguments: args,
        self: obj
      })
    end

    def get_class obj, context
      if obj.is_a? Gene::Types::Stream
        context.get_member("Stream")
      elsif obj.is_a? Array
        context.get_member("Array")
      elsif obj.is_a? Hash
        context.get_member("Hash")
      elsif obj.is_a? Gene::Types::Base
        context.get_member("Object")
      elsif obj.is_a? String
        context.get_member("String")
      elsif obj.is_a? Fixnum
        context.get_member("Int")
      elsif obj.is_a? Regexp
        context.get_member("Regexp")
      elsif obj.is_a? Range
        context.get_member("Range")
      elsif obj.is_a? TrueClass or obj.is_a? FalseClass
        context.get_member("Boolean")
      elsif obj.is_a? Gene::Types::Undefined
        context.get_member("Undefined")
      elsif obj == nil
        context.get_member("Null")
      elsif obj.is_a? Gene::Types::Symbol
        context.get_member("Symbol")
      elsif obj.is_a? Gene::Lang::Aspect
        context.get_member("Aspect")
      elsif obj.is_a? Gene::Lang::Class
        context.get_member("Class")
      elsif obj.class == Gene::Lang::Object
        context.get_member("Object")
      elsif obj.class == Gene::Lang::Context
        context.get_member("Context")
      elsif obj.class == Gene::Lang::BreakValue
        context.get_member("BreakValue")
      elsif obj.class == Gene::Lang::ReturnValue
        context.get_member("ReturnValue")
      else
        obj.class
      end
    end

    def render context, template
      if template.is_a? Gene::Types::Base
        if template.type == Gene::Types::Symbol.new('%')
          raise 'If you want to construct an expression, you should use "%%" or "%=" instead.'
        elsif template.type == Gene::Types::Symbol.new('%=')
          # new_type = template.data[0]
          # obj = Gene::Types::Base.new new_type, *template.data[1..-1]
          # obj.properties = template.properties
          # context.process_statements obj
          context.process_statements template.data
        elsif template.type.is_a?(Gene::Types::Symbol) and template.type.name[0] == '%'
          new_type = Gene::Types::Symbol.new(template.type.name[1..-1])
          obj = Gene::Types::Base.new new_type, *template.data
          obj.properties = template.properties
          context.process_statements obj
        elsif template.type == Gene::Types::Symbol.new('::')
          template.get(0)
        elsif template.type.is_a?(Gene::Types::Symbol) and template.type.name[0] == ':'
          new_type = Gene::Types::Symbol.new(template.type.name[1..-1])
          obj = Gene::Types::Base.new new_type, *template.data
          obj.properties = template.properties
          obj
        else
          result = Gene::Lang::Object.from_gene_base template
          result.type = render context, result.type
          result.properties.each do |name, value|
            # "#data" property is special and handled below
            next if ['#type', '#data'].include? name
            result.set name, render(context, value)
          end
          result.data.each_with_index do |item, index|
            rendered_item = render context, item
            handle_render_result result, index, rendered_item
          end
          result
        end
      elsif template.is_a? Gene::Types::Symbol and template.name[0] == '%'
        context.process_statements Gene::Types::Symbol.new(template.name[1..-1])
      elsif template.is_a? Array
        result = template.map {|item| render context, item }
      elsif template.is_a? Hash
        result = {}
        template.each do |name, value|
          result[name] = render context, value
        end
        result
      else
        template
      end
    end

    private

    def handle_render_result parent, index, child
      if child.is_a? Gene::Lang::Expandable
        parent.data.delete_at index
        child.value.each do |item|
          parent.data.insert index, item
          index += 1
        end
      else
        parent.data[index] = child
      end
    end
  end

  # Handle scope variables, instance variables like @var and literals
  class DefaultHandler
    include Utilities

    def call context, data
      if data.is_a? Gene::Types::Base
        if data.type.is_a?(Gene::Types::Symbol) and data.type == PLACEHOLDER
          obj = Gene::Lang::Object.new
          obj.data = data.data.map { |item| context.process(item) }
          data.properties.each do |key, value|
            obj.set key, context.process(value)
          end
          obj
        elsif data.type.is_a?(Gene::Types::Symbol) and data.type.to_s == ":"
          raise 'If you want to construct a Gene data, you should use "::" instead.'
        elsif data.type.is_a?(Gene::Types::Symbol) and data.type.to_s == "::"
          # obj = Gene::Types::Base.new data.data[0], *data.data[1..-1]
          # data.properties.each do |key, value|
          #   obj[key] = value
          # end
          # render context, obj
          render context, data.data[0]
        elsif data.type.is_a?(Gene::Types::Symbol) and data.type.to_s[0] == ":"
          obj = Gene::Types::Base.new Gene::Types::Symbol.new(data.type.to_s[1..-1]), *data.data
          data.properties.each do |key, value|
            obj[key] = value
          end
          render context, obj
        elsif INVOKE === data
          target = context.process data.data[0]
          method = context.process(data.data[1]).to_s
          args   = data.data[2..-1].to_a.map {|item| context.process(item) }
          args   = expand args
          target.send method, *args
        elsif NOT === data
          ! context.process(data.data[0])
        elsif PROP_NAME === data
          Gene::Lang::PropertyName.new context.process(data.data[0])
        elsif DO === data
          context.process_statements data.data
        elsif RETURN === data
          result = Gene::Lang::ReturnValue.new context.process(data.data[0])
          result
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
        elsif data.type.is_a? String
          children = data.data.map {|item| context.process(item) }
          data.type + expand(children).map{ |item| to_str(item, context) }.join
        else
          Gene::NOT_HANDLED
        end
      elsif data.is_a?(::Array) and not data.is_a?(Gene::Lang::Array)
        result = Gene::Lang::Array.new
        data.each do |item|
          value = context.process(item)
          if value.is_a? Gene::Lang::Expandable
            value = value.value
            if value.is_a? Array
              value.each do |x|
                result.push x
              end
            else
              result.push value
            end
          else
            result.push value
          end
        end
        result
      elsif data.is_a?(Hash) and not data.is_a?(Gene::Lang::Hash)
        result = Gene::Lang::Hash.new
        data.each do |key, value|
          processed = context.process value
          if processed.is_a? Gene::Lang::Expandable
            processed.value.each do |k, v|
              result[k] = v
            end
          else
            result[key] = processed
          end
        end
        result
      elsif data == PLACEHOLDER
        PLACEHOLDER
      elsif data == NOOP
        Gene::UNDEFINED
      elsif data == BREAK
        Gene::Lang::BreakValue.new
      elsif data == RETURN
        result = Gene::Lang::ReturnValue.new
        result
      elsif data == APPLICATION
        context.application
      elsif data == CONTEXT
        context
      elsif data == GLOBAL
        context.application.global_namespace
      elsif data == CURRENT_SCOPE
        context.scope
      elsif data == SELF
        context.self
      elsif data.is_a? Gene::Types::Symbol
        name = data.name
        if name[0] == ':'
          Gene::Types::Symbol.new name[1..-1]
        elsif name =~ /^(.*)\.\.\.$/
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
      klass.scope = Gene::Lang::Scope.new context.scope, false

      new_context = context.extend scope: klass.scope, self: klass
      # TODO: check whether Object class is defined.
      # If yes, and the newly defined class isn't Object and doesn't have a parent class, set Object as its parent class
      new_context.process_statements data.data[1..-1] || []
      if data['global']
        context.set_global name, klass
      else
        context.define name, klass, export: true
      end
      klass
    end
  end

  class ClassHandler
    def call context, data
      return Gene::NOT_HANDLED unless CLASS === data
      name  = data.data[0].to_s
      klass = Gene::Lang::Class.new name
      klass.scope = Gene::Lang::Scope.new context.scope, false

      stmts_start_index = 1
      if data.data[1] == EXTEND
        stmts_start_index += 2
        klass.parent_class = context.process data.data[2]
      end

      new_context = context.extend scope: klass.scope, self: klass
      # TODO: check whether Object class is defined.
      # If yes, and the newly defined class isn't Object and doesn't have a parent class, set Object as its parent class
      new_context.process_statements data.data[stmts_start_index..-1] || []
      if data['global']
        context.set_global name, klass
      else
        context.define name, klass, export: true
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
        if data['global']
          context.set_global name, fn
        else
          context.define name, fn, export: true
        end
      else
        name = ''
        fn   = Gene::Lang::Function.new name
      end

      # inherit_scope defaults to true unless its value is set to false
      if data['inherit_scope'] == false
        fn.inherit_scope = false
      else
        fn.inherit_scope = true
      end
      fn.parent_scope  = context.scope

      # eval_arguments defaults to true unless its value is set to false
      if data['eval_arguments'] == false
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

  class BindHandler
    def call context, data
      return Gene::NOT_HANDLED unless BIND === data

      fn    = context.process data.data[0]
      _self = context.process data.data[1]
      Gene::Lang::BoundFunction.new fn, _self
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
      name = data.data[0]
      if name.is_a? Gene::Types::Base
        name = context.process(name)
      end
      name = name.to_s
      fn = Gene::Lang::Function.new name
      fn.parent_scope = context.scope
      fn.inherit_scope = data.properties['inherit_scope']
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
      get.parent_scope = context.scope
      get.inherit_scope = false
      # Default code: [@x]  assume x is the property name
      code = data['get'] || [Gene::Types::Symbol.new("@#{name}")]
      get.args_matcher = Gene::Lang::Matcher.new
      get.args_matcher.from_array []
      get.statements = code
      context.self.methods[get.name] = get

      set = Gene::Lang::Function.new "#{name}="
      set.parent_scope = context.scope
      set.inherit_scope = false
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

      hierarchy = Gene::Lang::HierarchySearch.new(klass.ancestors)
      method = INIT.name
      args = data.data[1..-1].map {|arg| context.process arg }
      args = Gene::Lang::Object.from_array_and_properties(args, data.properties)
      hierarchy.next.handle_method({
        hierarchy: hierarchy,
        method: method,
        context: context,
        arguments: args,
        self: instance
      })

      instance
    end
  end

  class CallHandler
    def call context, data
      return Gene::NOT_HANDLED unless CALL === data
      function = context.process data.data[0]
      self_object = context.process data.data[1]
      args = data.data[2..-1] || []
      args = Gene::Lang::Object.from_array_and_properties(args, data.properties)
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
      fn.parent_scope = context.scope
      fn.inherit_scope = false
      fn.args_matcher = Gene::Lang::Matcher.new
      fn.args_matcher.from_array data.data[0]
      fn.statements = data.data[1..-1]
      context.self.methods[INIT.name] = fn
      fn
    end
  end

  class DefinitionHandler
    def call context, data
      return Gene::NOT_HANDLED unless VAR === data or NSVAR === data
      name  = data.data[0].to_s
      value = context.process data.data[1]
      if name[0] == '@'
        context.self.set_member name[1..-1], value
      else
        context.define name, value, namespace: data.type == NSVAR, export: data['export']
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
        args = Gene::Lang::Object.from_array_and_properties(args, data.properties)
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
        if value.is_a?(Gene::Lang::Function) or value.is_a?(Gene::Lang::BoundFunction)
          if value.eval_arguments
            args = args.map{|item| context.process item}
          end
          if data.get('#render_args')
            data.properties.delete '#render_args'
            args = render context, args
          end
          args = expand args
          args = Gene::Lang::Object.from_array_and_properties(args, data.properties)
          value.call context: context, arguments: args
        else
          raise "Invocation is not supported for #{data.inspect}"
        end
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Types::Symbol and data.type.name =~ /^.(.*)$/
        method = $1
        klass = get_class(context.self, context)
        hierarchy = Gene::Lang::HierarchySearch.new(klass.ancestors)
        args = data.data.map{|item| context.process item}
        args = expand args
        args = Gene::Lang::Object.from_array_and_properties(args, data.properties)
        # args.properties = data.properties
        hierarchy.next.handle_method(
          hierarchy: hierarchy,
          method: method,
          context: context,
          arguments: args,
          self: context.self
        )
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Types::Base
        new_data = data.clone
        new_data.type = context.process new_data.type
        context.process new_data
      elsif data.is_a? Gene::Types::Base and data.type.is_a? Gene::Lang::Function
        # TODO: check eval_arguments
        args = data.data.map{|item| context.process item}
        args = expand args
        args = Gene::Lang::Object.from_array_and_properties(args, data.properties)
        data.type.call context: context, arguments: args
      else
        Gene::NOT_HANDLED
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
      Gene::Types::Symbol.new('&='),
      Gene::Types::Symbol.new('|='),
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
      when '&='  then old_value &  change_value
      when '|='  then old_value |  change_value
      when '&&=' then old_value && change_value
      when '||=' then old_value || value
      else raise "Invalid operator #{op.inspect}"
      end
    end
  end

  class AspectHandler
    def call context, data
      return Gene::NOT_HANDLED unless ASPECT === data

      name   = data.data[0].to_s
      aspect = Gene::Lang::Aspect.new name

      scope = Gene::Lang::Scope.new context.scope, false
      new_context = context.extend scope: scope, self: aspect
      new_context.process_statements data.data[1..-1] || []
      if data['global']
        context.set_global name, aspect
      else
        context.define name, aspect, export: true
      end
      aspect
    end
  end

  class AdviceHandler
    def call context, data
      return Gene::NOT_HANDLED unless BEFORE === data or AFTER === data or WHEN === data

      advice = Gene::Lang::Advice.new data.type.to_s
      advice.method_matcher = data.data[0]
      advice.args_matcher = data.data[1]
      advice.logic = data.data[2..-1]

      if context.self.is_a? Gene::Lang::Aspect
        aspect = context.self
      elsif context.self.is_a? Gene::Lang::Module
        if not context.self.default_aspect
          context.self.default_aspect = Gene::Lang::Aspect.new 'default'
        end
        aspect = context.self.default_aspect
      end

      if BEFORE === data
        aspect.before_advices << advice
      elsif AFTER === data
        aspect.after_advices << advice
      else
        aspect.when_advices << advice
      end

      advice
    end
  end

  class ContinueHandler
    def call context, data
      return Gene::NOT_HANDLED unless CONTINUE === data

      method    = context.get_member('$method')
      args      = context.get_member('$arguments')
      hierarchy = context.get_member('$hierarchy')
      advices   = context.get_member('$advices')
      hierarchy.current.handle_method(
        context: context,
        method: method,
        hierarchy: hierarchy,
        arguments: args,
        advices: advices,
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

      Gene::Types::Symbol.new('=~'),
      Gene::Types::Symbol.new('!~'),

      Gene::Types::Symbol.new('+'),
      Gene::Types::Symbol.new('-'),
      Gene::Types::Symbol.new('*'),
      Gene::Types::Symbol.new('/'),
      Gene::Types::Symbol.new('|'),
      Gene::Types::Symbol.new('&'),

      Gene::Types::Symbol.new('&&'),
      Gene::Types::Symbol.new('||'),

      Gene::Types::Symbol.new('..'),
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

      when '=~' then left =~ right
      when '!~' then left !~ right

      when '+' then left + right
      when '-' then left - right
      when '*' then left * right
      when '/' then left / right
      when '|' then left | right
      when '&' then left & right

      when '&&' then left && right
      when '||' then left || right
      when '..' then Range.new(left, right)
      end
    end
  end

  class IfHandler
    def call context, data
      return Gene::NOT_HANDLED unless IF === data or IF_NOT === data
      # return Gene::NOT_HANDLED unless IF === data

      handle context, data.type, data.data[0], data.data[1..-1]
    end

    def handle context, type, condition, rest
      result = Gene::UNDEFINED
      condition = context.process condition
      if condition == Gene::UNDEFINED
        condition = false
      end
      index = 0
      in_else = false

      allow_then = true
      while index < rest.length
        stmt   = rest[index]
        index += 1

        if allow_then
          allow_then = false
          if stmt == THEN
            stmt   = rest[index]
            index += 1
          end
        end

        if stmt == ELSE
          if type == IF_NOT
            raise '"else" is not supported in "if_not"'
          end
          if condition
            break
          end
          in_else = true
          next
        elsif stmt == ELSE_IF
          if type == IF_NOT
            raise '"else_if" is not supported in "if_not"'
          end
          if condition
            break
          end
          new_condition = rest[index]
          index += 1
          condition = context.process new_condition
          if condition == Gene::UNDEFINED
            condition = false
          end
          allow_then = true
          next
        end

        if condition
          if type != IF_NOT and not in_else
            result = context.process stmt
          end
        else
          if type == IF_NOT or in_else
            result = context.process stmt
          end
        end
      end

      result
    end
  end

  # class ForHandler
  #   def call context, data
  #     return Gene::NOT_HANDLED unless FOR === data
  #     # initialize
  #     context.process data.data[0]

  #     condition = data.data[1]
  #     update    = data.data[2]
  #     # (for _ _ _ ...) is same as (loop ...)
  #     # _ is treated as true in place of condition
  #     while condition == PLACEHOLDER ||
  #           ((value = context.process(condition)) && value != Gene::UNDEFINED)
  #       # TODO: add tests for next, break and return
  #       result = context.process_statements data.data[3..-1] || []
  #       if result.is_a? Gene::Lang::ReturnValue
  #         return result
  #       elsif result.is_a? Gene::Lang::BreakValue
  #         break result.value
  #       end
  #       context.process update
  #     end

  #     # TODO: for loop should return last value from the inside, NOT what the condition evaluates to
  #     Gene::UNDEFINED
  #   end
  # end

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

      name  = data.data[0].to_s
      scope = Gene::Lang::Scope.new context.scope, false
      ns    = Gene::Lang::Namespace.new name, scope
      context.define name, ns, export: true

      # new_context             = Gene::Lang::Context.new
      # new_context.application = context.application
      # new_context.self        = ns
      # new_context.namespace   = ns
      new_context = context.extend self: ns, scope: ns.scope, namespace: ns
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
        if not new_context.scope.defined_in_ns? name
          raise "#{name} is neither defined nor exported."
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

  class WithHandler
    def call context, data
      return Gene::NOT_HANDLED unless WITH === data

      _self = context.process data.data[0]
      new_context = context.extend self: _self

      result = Gene::UNDEFINED
      data.data[1..-1].each do |item|
        result = new_context.process item
      end

      result
    end
  end

  class ScopeHandler
    def call context, data
      return Gene::NOT_HANDLED unless SCOPE === data

      scope = Gene::Lang::Scope.new context.scope, data.properties['inherit_scope']
      new_context = context.extend scope: scope

      result = Gene::UNDEFINED
      data.data.each do |item|
        result = new_context.process item
      end

      result
    end
  end

  class MatchHandler
    def call context, data
      return Gene::NOT_HANDLED unless MATCH === data

      pattern = data.data[0]
      target  = context.process data.data[1]
      match pattern, target, context
    end

    def match pattern, target, context
      if pattern.is_a? Gene::Types::Base
        if pattern.type != PLACEHOLDER
          if target.is_a? Array
            value = Gene::Types::Symbol.new('Array')
          elsif target.is_a? Hash
            value = Gene::Types::Symbol.new('Hash')
          elsif target.is_a?(Gene::Lang::Object) or target.is_a?(Gene::Types::Base)
            value = target.type
          else
            value = Gene::Types::Symbol.new(target.class.to_s)
          end

          context.define pattern.type.name, value
        end

        triple_dot_seen = false # name... or ... is seen
        pattern.data.each_with_index do |name, i|
          mapped_index = i
          if triple_dot_seen
            mapped_index = i - pattern.data.length
          elsif name.is_a? Gene::Types::Symbol
            if name.to_s == '...'
              triple_dot_seen = true
              next
            elsif name.to_s =~ /\.\.\.$/
              triple_dot_seen = true
              mapped_index = i..(i - pattern.data.length)
            end
          end

          if target.is_a?(Gene::Lang::Object) or target.is_a?(Gene::Types::Base)
            if mapped_index.is_a?(Range) or mapped_index < target.data.size
              result = target.data[mapped_index]
            else
              result = Gene::UNDEFINED
            end
          elsif target.is_a? Array
            if mapped_index.is_a?(Range) or mapped_index < target.size
              result = target[mapped_index]
            else
              result = Gene::UNDEFINED
            end
          else
            result = Gene::UNDEFINED
          end

          if name.is_a? Gene::Types::Symbol
            context.define name.to_s.gsub(/\.\.\.$/, ''), result
          else
            match name, result, context
          end
        end
        pattern.properties.each do |key, value|
          if target.is_a?(Gene::Lang::Object) or target.is_a?(Gene::Types::Base)
            result = target.get(key.to_s)
          elsif target.is_a? Hash
            result = target[key.to_s]
          else
            result = Gene::UNDEFINED
          end

          if value == true
            context.define key.to_s, result
          else
            match value, result, context
          end
        end
      elsif pattern.is_a? Array
        triple_dot_seen = false # name... or ... is seen
        pattern.each_with_index do |name, i|
          mapped_index = i
          if triple_dot_seen
            mapped_index = i - pattern.length
          elsif name.is_a? Gene::Types::Symbol
            if name.to_s == '...'
              triple_dot_seen = true
              next
            elsif name.to_s =~ /\.\.\.$/
              triple_dot_seen = true
              mapped_index = i..(i - pattern.length)
            end
          end

          if target.is_a?(Gene::Lang::Object) or target.is_a?(Gene::Types::Base)
            if mapped_index.is_a?(Range) or mapped_index < target.data.size
              result = target.data[mapped_index]
            else
              result = Gene::UNDEFINED
            end
          elsif target.is_a? Array
            if mapped_index.is_a?(Range) or mapped_index < target.size
              result = target[mapped_index]
            else
              result = Gene::UNDEFINED
            end
          else
            result = Gene::UNDEFINED
          end

          if name.is_a? Gene::Types::Symbol
            context.define name.to_s.gsub(/\.\.\.$/, ''), result
          else
            match name, result, context
          end
        end
      elsif pattern.is_a? Hash
        pattern.each do |key, value|
          if target.is_a?(Gene::Lang::Object) or target.is_a?(Gene::Types::Base)
            result = target.get(key.to_s)
          elsif target.is_a? Hash
            result = target[key.to_s]
          else
            result = Gene::UNDEFINED
          end

          if value == true
            context.define key.to_s, result
          else
            match value, result, context
          end
        end
      elsif pattern.is_a? Gene::Types::Symbol
        context.define pattern.name, target
      end
    end
  end

  class ExpandHandler
    def call context, data
      return Gene::NOT_HANDLED unless EXPAND === data

      Gene::Lang::Expandable.new context.process(data.data[0])
    end
  end

  class EvalHandler
    include Utilities

    def call context, data
      return Gene::NOT_HANDLED unless EVAL === data

      result = Gene::UNDEFINED
      data.data.each do |item|
        # First round: treat each item as an argument
        result = context.process item
        # Second round: evaluate each result
        result = context.process result
      end
      result
    end
  end

  class PrintHandler
    def call context, data
      return Gene::NOT_HANDLED unless PRINT === data or PRINTLN === data

      data.data.each do |item|
        print context.process item
      end
      print "\n" if PRINTLN === data
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

  class ExceptionHandler
    def call context, data
      return Gene::NOT_HANDLED unless THROW === data or CATCH === data

      if THROW === data
        klass = context.process data.data[0]
        if klass.is_a?(Gene::Lang::Class) and klass.ancestors.include?(context.get_member('Throwable'))
          if data.data.length > 1
            message = context.process data.data[1]
          end
        else
          message = klass
          klass = context.get_member('Exception')
        end

        exception = Gene::Lang::Object.new klass
        exception.set 'message', message
        raise Gene::Lang::ExceptionWrapper.new(exception)
      else
        begin
          context.process_statements data.data
        rescue Gene::Lang::ExceptionWrapper => wrapper
          exception = wrapper.wrapped_exception

          handled = false

          data.properties.each do |key, value|
            next if key == 'ensure'

            if exception.class.name == key or (key == 'default' and exception.class.name == 'Exception')
              handled = true
              handler = context.process value
              args = Gene::Lang::Object.from_array_and_properties [exception]
              result = handler.call context: context, arguments: args
              break
            end
          end

          ensure_cb = data.properties['ensure']
          if ensure_cb
            function = context.process ensure_cb
            args = Gene::Lang::Object.from_array_and_properties []
            function.call context: context, arguments: args
          end

          if not handled
            raise wrapper
          end
        end
      end
    end
  end

  class RenderHandler
    include Utilities

    def call context, data
      return Gene::NOT_HANDLED unless RENDER === data

      template = data.data[0]
      render context, template
    end
  end

  class CatchAllHandler
    def call context, data
      raise "Should not reach here: input=#{data.inspect}"
    end
  end
end
