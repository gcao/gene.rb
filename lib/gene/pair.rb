module Gene
  class Pair
    attr_reader :first, :second

    def initialize first, second
      @first  = first
      @second = second
    end

    def == other
      return true if other == NOOP and (first == NOOP or second == NOOP)

      return unless other.is_a? self.class

      first == other.first and second == other.second
    end

    def to_s
      "#{first} : #{second}"
    end
  end
end
