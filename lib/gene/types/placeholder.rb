module Gene
  module Types
    class Placeholder
      def == other
        other.is_a? self.class
      end

      def to_s
        '#_'
      end
    end
  end

  PLACEHOLDER = Gene::Types::Placeholder.new()
end
