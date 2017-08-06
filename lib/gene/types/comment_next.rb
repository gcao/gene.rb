module Gene
  module Types
    class CommentNext
      def == other
        other.is_a? self.class
      end

      def to_s
        '##'
      end
    end
  end

  COMMENT_NEXT = Gene::Types::CommentNext.new()
end
