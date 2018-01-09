module Gene
  module Types
    class Undefined
      def == other
        other.is_a? self.class
      end

      def to_s
        ''
      end

      def inspect
        'undefined'
      end
    end
  end

  UNDEFINED = Gene::Types::Undefined.new()
end
