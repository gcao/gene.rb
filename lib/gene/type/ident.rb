module Gene
  module Type
    class Ident < Base
      attr :name

      def initialize name
        @name = name
      end
    end
  end
end

