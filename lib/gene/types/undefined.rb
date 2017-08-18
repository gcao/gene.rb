module Gene
  module Types
    class Undefined
      def == other
        other.is_a? self.class
      end

      def to_s
        'undefined'
      end
      alias inspect to_s
    end
  end

  UNDEFINED = Gene::Types::Undefined.new()
end
