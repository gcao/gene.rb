module Gene
  class Pairs < Array
    def initialize *items
      concat items
    end

    def rest
      self[1..-1]
    end

    def == other
      return unless other.is_a? Pairs

      super
    end

    def to_s
      s = "{"
      s << map do |pair|
        pair.to_s
      end.join(' ')
      s << "}"
    end
  end
end
