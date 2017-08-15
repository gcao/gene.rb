module Gene::Macro::Handlers
  DEF = Gene::Types::Ident.new '#def'
  DEF_RETAIN = Gene::Types::Ident.new '#def-retain'
  FN = Gene::Types::Ident.new '#fn'

  class DefaultHandler
    def call context, data
      if data.is_a? Gene::Types::Ident and data.name =~ /^#@(.*)$/
        context.scope[$1]

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

      elsif data.is_a? Gene::Types::Group
        name = data.first.name.to_s
        if name =~ /^\#\@(.*)$/
          value = context.scope[$1]
          if value.is_a? Gene::Macro::Function
            value.call context, data[1..-1]
          else
            data[0] = value
            return data
          end
        end

      # elsif data.is_a? Array
      #   (data.size - 1).downto(0) do |i|
      #     result = context.process(data[i])
      #     if result == Gene::Macro::IGNORE
      #       data.delete_at i
      #     else
      #       data[i] = result
      #     end
      #   end

      # elsif data.is_a? Hash

      else
        data
      end
    end
  end
end
