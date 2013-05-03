module Gene
  class Group
    attr :children

    def initialize *children
      @children = children
    end

    def first
      children.first
    end

    def rest
      children[1..-1]
    end

    def == other
      return unless other.is_a? Group

      children == other.children
    end
  end
end
