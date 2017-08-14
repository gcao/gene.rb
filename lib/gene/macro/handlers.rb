module Gene::Macro::Handlers
  DEF = Gene::Types::Ident.new '#def'
  RETAIN = Gene::Types::Ident.new '#retain'

  class DefaultHandler
    def call context, data
      if data.is_a? Gene::Types::Ident and data.name =~ /^#@(.*)$/
        context.scope[$1]
      elsif DEF.first_of_group? data
        value = context.process data.third
        context.scope[data.second.to_s] = value
        if data[3] == RETAIN
          value
        else
          Gene::Macro::IGNORE
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
