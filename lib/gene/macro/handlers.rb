module Gene::Macro::Handlers
  DEF         = Gene::Types::Ident.new '#def'
  DEF_RETAIN  = Gene::Types::Ident.new '#def-retain'
  FN          = Gene::Types::Ident.new '#fn'

  MAP         = Gene::Types::Ident.new '#map'

  IF          = Gene::Types::Ident.new '#if'
  THEN        = Gene::Types::Ident.new '#then'
  ELSE        = Gene::Types::Ident.new '#else'

  ENV_        = Gene::Types::Ident.new '#env'
  CWD         = Gene::Types::Ident.new '#cwd'
  LS          = Gene::Types::Ident.new '#ls'
  READ        = Gene::Types::Ident.new '#read'

  GET         = Gene::Types::Ident.new '#get'

  class DefaultHandler
    def call context, data
      if data.is_a? Gene::Types::Ident and data.name =~ /^##(.*)$/
        context.scope[$1]

      elsif data == CWD
        Dir.pwd

      elsif DEF.first_of_group? data
        value = context.process data.third
        context.scope[data.second.to_s] = value
        Gene::Macro::IGNORE

      elsif DEF_RETAIN.first_of_group? data
        value = context.process data.third
        context.scope[data.second.to_s] = value
        value

      elsif FN.first_of_group? data
        name = data[1].to_s
        arguments = [data[2]].flatten.map &:to_s
        statements = data[3..-1]
        context.scope[name] = Gene::Macro::Function.new name, arguments, statements

      elsif MAP.first_of_group? data
        collection = data[1]
        arguments = ['_index', '_value']
        statements = data[2..-1]
        fn = Gene::Macro::AnonymousFunction.new arguments, statements
        collection.each_with_index.map do |item, i|
          fn.call context, [i, item]
        end

      elsif IF.first_of_group? data
        condition = context.process data[1]
        then_mode = data[2] == THEN
        if then_mode
          result = Gene::UNDEFINED
          if condition
            data[3..-1].each do |item|
              break if item == ELSE
              result = context.process item
            end
          else
            found_else = false
            data[3..-1].each do |item|
              if found_else
                result = context.process item
              elsif item == ELSE
                found_else = true
              end
            end
          end
          result
        else
          if condition
            context.process data[2]
          else
            context.process data[3]
          end
        end

      elsif ENV_.first_of_group? data
        name = data[1].to_s
        ENV[name]

      elsif LS.first_of_group? data
        name = data[1] || Dir.pwd
        Dir.entries name.to_s

      elsif READ.first_of_group? data
        name = data[1]
        File.read name

      elsif GET.first_of_group? data
        target = data[1]
        path   = data[2..-1]
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
        name = data.first.name.to_s
        if name =~ /^##(.*)$/
          value = context.scope[$1]
          if value.is_a? Gene::Macro::Function
            value.call context, data[1..-1]
          else
            data[0] = value
            return data
          end
        else
          data
        end

      elsif data.is_a? Array
        data
          .map    {|item| context.process item }
          .select {|item| item != Gene::Macro::IGNORE }

      # elsif data.is_a? Hash

      else
        data
      end
    end
  end
end
