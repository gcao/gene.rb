module Gene
  class Group < Array
    def initialize *items
      concat items
    end

    def context
      @context ||= Context.new(self)
    end

    def rest
      self[1..-1]
    end

    def == other
      return unless other.is_a? Group

      super
    end

    def to_s
      s = "("
      s << map do |child|
        if child.is_a? String
          child.inspect
        else
          child.to_s
        end
      end.join(' ')
      s << ")"
    end

    def inspect
      s = "("
      s << map do |pair|
        pair.inspect
      end.join(' ')
      s << ")"
    end
  end
end