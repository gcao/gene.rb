module Gene
  class Path
    class NotFoundError < StandardError
    end

    NOT_FOUND = Object.new

    attr_reader :items

    def initialize *items
      @items = items.map {|item| Item.from(item) }
    end

    # Return first item in data that matches this path
    def find_in data
      result = data
      items.each do |item|
        result = item.find_in result

        if result == NOT_FOUND
          break
        end
      end

      result
    end

    # Return all items in data that matches this path
    def find_all_in data
    end

    class ItemBase
      def find_in data
        raise NotImplementedError
      end

      def find_all_in data
        raise NotImplementedError
      end
    end

    class Item < ItemBase
      attr_reader :value

      def initialize value
        @value = value
      end

      def find_in data
        case value
        when String
          case data
          when Hash, Gene::Types::Base
            data[value]
          else
            NOT_FOUND
          end
        when Integer
          case data
          when Array
            data[value]
          when Gene::Types::Base
            data.data[value]
          else
            NOT_FOUND
          end
        else
          NOT_FOUND
        end
      end

      def find_all_in data
      end

      def self.from value
        self.new(value)
      end
    end

    class Type < ItemBase
      def find_in data
        case data
        when Gene::Types::Base
          data.type
        else
          Gene::Types::Symbol.new(data.class.to_s)
        end
      end

      def find_all_in data
      end
    end
  end
end
