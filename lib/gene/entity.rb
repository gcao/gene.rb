module Gene
  class Entity
    attr :name

    def initialize name
      @name = name
    end

    def == other
      return false unless other.is_a? self.class
      @name == other.name
    end

    def to_s
      name.gsub(/([\(\)\[\]\{\}])/, '[' => '\\[', ']' => '\\]', '(' => '\\(', ')' => '\\)', '{' => '\\{', '}' => '\\}')
    end
  end
end

