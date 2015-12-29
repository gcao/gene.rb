module Gene
  module Types
    class Stream < Array
      def initialize *items
        concat items
      end

      def == other
        return unless other.is_a? Stream

        super
      end

      def to_s
         map do |child|
          if child.is_a? String
            child
          else
            child.to_s
          end
        end.join(' ')
      end

      def inspect
        to_s
      end
    end
  end
end
