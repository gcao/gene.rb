module Gene
  class Path
    class NotFoundError < StandardError
    end

    NOT_FOUND = Object.new

    attr_accessor :name
    attr_accessor :desc
    attr_reader :items

    # (#Path ^name "test"
    #   (child ^guard (> (self) 1)
    #     *
    #   )
    # )
    # Input: (a 0 1 2 3)
    # After applying above path on the input,
    #   find_in(input) should return 2
    #   find_all_in(input) should return [2, 3]
    def self.from_gene
    end

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
      def guards
        @guards ||= []
      end

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
        case value
        when String, Integer
          result = find_in data
          if result == NOT_FOUND
            []
          else
            [result]
          end
        else
          []
        end
      end

      def self.from value
        if value.is_a? ItemBase
          value
        else
          self.new(value)
        end
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
        [find_in(data)]
      end
    end

    TYPE = Type.new

    class Guard
      attr_reader :type
      attr_reader :sub_path
      attr_reader :value

      def initialize type, sub_path, value
        @type = type
        @sub_path = sub_path
        @value = value
      end

      def check
      end
    end
  end
end
