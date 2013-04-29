module Gene
  class Entity
    attr :name

    def initialize name
      @name = name
    end

    def == other
      return unless other.is_a? self.class
      @name == other.name
    end
  end
end

