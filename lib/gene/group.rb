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

    def to_s
      s = "("
      s << children.map do |child|
        if child.is_a? String
          child.inspect
        else
          child.to_s
        end
      end.join(' ')
      s << ")"
    end
  end
end
