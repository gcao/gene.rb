module Gene
  module Types
    class Noop
      def == other
        other.is_a? self.class
      end

      def to_s
        '()'
      end
    end
  end

  NOOP = Gene::Types::Noop.new()
end
