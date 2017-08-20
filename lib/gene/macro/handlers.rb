module Gene::Macro::Handlers
  DEF         = Gene::Types::Ident.new '#def'
  DEF_RETAIN  = Gene::Types::Ident.new '#def-retain'
  FN          = Gene::Types::Ident.new '#fn'
  FNX         = Gene::Types::Ident.new '#fnx'
  DO          = Gene::Types::Ident.new '#do'
  INPUT       = Gene::Types::Ident.new '#input'

  MAP         = Gene::Types::Ident.new '#map'
  FOR         = Gene::Types::Ident.new '#for'

  YIELD       = Gene::Types::Ident.new '#yield'

  IF          = Gene::Types::Ident.new '#if'
  THEN        = Gene::Types::Ident.new '#then'
  ELSE        = Gene::Types::Ident.new '#else'

  ENV_        = Gene::Types::Ident.new '#env'
  CWD         = Gene::Types::Ident.new '#cwd'
  LS          = Gene::Types::Ident.new '#ls'
  READ        = Gene::Types::Ident.new '#read'

  GET         = Gene::Types::Ident.new '#get'

  LT          = Gene::Types::Ident.new '#lt'
  LE          = Gene::Types::Ident.new '#le'

  INCR        = Gene::Types::Ident.new '#incr'
  DECR        = Gene::Types::Ident.new '#decr'

  class DefaultHandler
    def call context, data
      if data.is_a? Gene::Types::Ident and data.name =~ /^##(.*)$/
        context.scope[$1]

      elsif data == CWD
        Dir.pwd

      elsif data == INPUT
        context.inputs[0] if context.inputs

      elsif DEF === data
        value = context.process_internal data.data[1]
        context.scope[data.data[0].to_s] = value
        Gene::Macro::IGNORE

      elsif DEF_RETAIN === data
        value = context.process_internal data.data[1]
        context.scope[data.data[0].to_s] = value
        value

      elsif FN === data
        name = data.data[0].to_s
        arguments = [data.data[1]].flatten.map(&:to_s).reject{|arg| arg == '_' }
        statements = data.data[2..-1]
        context.scope[name] = Gene::Macro::Function.new name, context.scope, arguments, statements
        Gene::Macro::IGNORE

      elsif FNX === data
        arguments = [data.data[0]].flatten.map(&:to_s).reject{|arg| arg == '_' }
        statements = data.data[1..-1]
        context.scope[name] = Gene::Macro::Function.new '', context.scope, arguments, statements

      elsif DO === data
        result = Gene::UNDEFINED
        data.data.each do |stmt|
          result = context.process_internal stmt
        end
        result

      elsif MAP === data
        collection = data.data.shift
        value_var_name = data.data.shift

        next_item = data.data.shift
        if next_item == DO
          index_var_name = nil
        else
          index_var_name = next_item
          next_item = data.data.shift
          if next_item != DO
            throw "Syntax error: #do is expected"
          end
        end

        statements = data.data
        collection.each_with_index.map do |item, i|
          context.scope[value_var_name.name] = item
          context.scope[index_var_name.name] = i if index_var_name

          result = nil
          statements.each do |stmt|
            result = context.process_internal stmt
          end
          result
        end

      elsif IF === data
        condition = context.process_internal data.data[0]
        then_mode = data.data[1] == THEN
        if then_mode
          result = Gene::UNDEFINED
          if condition
            data.data[2..-1].each do |item|
              break if item == ELSE
              result = context.process_internal item
            end
          else
            found_else = false
            data.data[2..-1].each do |item|
              if found_else
                result = context.process_internal item
              elsif item == ELSE
                found_else = true
              end
            end
          end
          result
        else
          if condition
            context.process_internal data.data[1]
          else
            context.process_internal data.data[2]
          end
        end

      elsif ENV_ === data
        name = data.data[0].to_s
        ENV[name]

      elsif LS === data
        name = data.data[0] || Dir.pwd
        Dir.entries name.to_s

      elsif READ === data
        name = data.data[0]
        File.read name.to_s

      elsif LT === data
        first  = context.process_internal data.data[0]
        second = context.process_internal data.data[1]
        first < second

      elsif LE === data
        first  = context.process_internal data.data[0]
        second = context.process_internal data.data[1]
        first <= second

      elsif INCR === data
        name = data.data[0].to_s
        context.scope[name] += 1

      elsif FOR === data
        do_index = data.data.index DO
        init, cond, incr = data.data[0..do_index]
        rest = data.data[(do_index + 1)..-1]

        context.process_internal init if init

        yield_values = Gene::Macro::YieldValues.new

        while cond and context.process_internal(cond)
          rest.each do |stmt|
            value = context.process_internal stmt
            if value.is_a? Gene::Macro::YieldValue
              yield_values.values << value.value
            elsif value.is_a? Gene::Macro::YieldValues
              yield_values.values.concat value.values
            end
          end
          context.process_internal incr
        end

        if yield_values.empty?
          Gene::Macro::IGNORE
        else
          yield_values
        end

      elsif YIELD === data
        value = context.process_internal data.data[0]
        Gene::Macro::YieldValue.new value

      elsif GET === data
        target = context.process_internal data.data[0]
        path   = data.data[1..-1]
        path.each do |item|
          break unless target
          if target.is_a? Hash
            # target[item] does not work
            key = target.keys.find {|k| k.eql? item }
            if key
              target = target[key]
            else
              nil
            end
          else
            target = target[item]
          end
        end
        target

      elsif data.is_a? Gene::Types::Base
        data.attributes.each do |key, value|
          value = context.process_internal value
          if value == Gene::UNDEFINED
            data.attributes.delete key
          else
            data[key] = value
          end
        end

        data.data = data.data
          .map    {|item| context.process_internal item }
          .select {|item| item != Gene::Macro::IGNORE }

        convert_yield_values data.data

        name = data.type.to_s
        if name =~ /^##(.*)$/
          value = context.scope[$1]
          if value.is_a? Gene::Macro::Function
            return value.call context, data.data
          else
            data.type = value
          end
        end

        data

      elsif data.is_a? Array
        result = data
          .map    {|item| context.process_internal item }
          .select {|item| item != Gene::Macro::IGNORE }

        convert_yield_values result

      elsif data.is_a? Hash
        result = {}
        data.each do |key, value|
          value = context.process_internal value
          if value != Gene::UNDEFINED
            result[key] = value
          end
        end
        result

      else
        data
      end
    end

    private

    def convert_yield_values array
      (array.size - 1).downto 0 do |i|
        item = array[i]
        if item.is_a? Gene::Macro::YieldValues
          array.delete_at i
          item.values.reverse.each do |value|
            array.insert i, value
          end
        end
      end

      array
    end
  end
end
