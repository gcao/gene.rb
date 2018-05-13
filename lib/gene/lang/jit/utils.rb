module Gene::Lang::Jit
  module Utils
    def process_decorators data
      if data.is_a? Gene::Types::Stream
        process_decorators_in_array data
      elsif data.is_a? Array
        process_decorators_in_array data
      elsif data.is_a? Gene::Types::Base
        data.data = process_decorators_in_array data.data
        data
      else
        data
      end
    end

    private

    def process_decorators_in_array data
      decorators = []
      i = 0
      while i < data.length
        item = data[i]
        if is_decorator? item
          decorators.push item
          data.delete_at i
        elsif decorators.empty?
          i += 1
        else
          data[i] = apply_decorators decorators, item
          decorators = []
          i += 1
        end
      end

      data
    end

    def is_decorator? item
      (item.is_a? Gene::Types::Symbol and item.is_decorator?) or
      (item.is_a? Gene::Types::Base and item.type.is_a? Gene::Types::Symbol and item.type.is_decorator?)
    end

    def apply_decorators decorators, item
      while not decorators.empty?
        decorator = decorators.pop

        item =
          if decorator.is_a? Gene::Types::Symbol
            Gene::Types::Base.new Gene::Types::Symbol.new(decorator.to_s[1..-1]), item
          else
            decorator.type = Gene::Types::Symbol.new(decorator.type.to_s[1..-1])
            Gene::Types::Base.new decorator, item
          end
      end

      item
    end
  end
end
