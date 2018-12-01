module Gene
  class Path
    class NotFoundError < StandardError
    end

    NOT_FOUND = Object.new

    OR = Gene::Types::Symbol.new('|')

    attr_accessor :name
    attr_accessor :desc
    attr_reader :matcher

    # (#Path 1 2 3)
    # =>
    # Match third child of second child of first child
    # Not match first, second and third of root

    # (#Path 1 | 2 | 3)
    # =>
    # Match first, second and third of root

    # (#Path 1 [2 | 3] | 4 5)
    # =>
    # (#Path (choices (branch (item 1) (choices (item 2) (item 3)) (branch (item 4) (item 5))))

    # (#Path ^name "test"
    #   (child ^guard (> (self) 1)
    #     *
    #   )
    # )
    # Input: (a 0 1 2 3)
    # After applying above path on the input,
    #   find(input) should return 2
    #   find_all(input) should return [2, 3]
    def self.from_gene
    end

    # First check wehether there is '|'
    # If yes, create a branch object and add
    def initialize *items
      @matcher = Item.from items
    end

    # Return first item in data that matches this path
    def find data
      result = @matcher.find data
      result == NOT_FOUND ? nil : result
    end

    # Return all items in data that matches this path
    def find_all data
      @matcher.find_all data
    end

    class ItemBase
      attr_reader :parent
      attr_reader :children
      attr_reader :guards

      def initialize parent = nil
        @parent = parent
      end

      def guards
        @guards ||= []
      end

      def find data
        raise NotImplementedError
      end

      def find_all data
        raise NotImplementedError
      end
    end

    class Item < ItemBase
      attr_reader :value

      def initialize value
        @value = value
      end

      def find data
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

      def find_all data
        case value
        when String, Integer
          result = find data
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
        case value
        when ItemBase
          value
        when Array
          choices = []
          branch = []
          choices.push branch
          value.each do |item|
            if item == OR
              branch = []
              choices.push branch
            else
              branch.push from(item)
            end
          end

          if choices.length == 1
            if branch.length == 1
              branch.first
            else
              Branch.new *branch
            end
          else
            Choices.new(choices.map{|choice|
              if choice.length == 1
                Item.from choice.first
              else
                Branch.new *branch
              end
            })
          end
        else
          self.new(value)
        end
      end
    end

    # For matching gene or map, return a map
    # Not applicable to other objects
    class Map < ItemBase
    end

    # For matching Gene or Map, return a pair of key/value
    # Not applicable to other objects
    class Pair < ItemBase
    end

    # Collection of path items
    class Branch < ItemBase
      attr_reader :items

      def initialize *items
        @items = items
      end

      def find data
        found = data

        @items.each do |item|
          found = item.find found
          if found == NOT_FOUND
            break
          end
        end

        found
      end

      def find_all data
        found = [data]

        @items.each do |item|
          new_found = []
          found.each do |v|
            new_found.concat item.find_all(v)
          end
          if new_found.empty?
            break
          else
            found = new_found
          end
        end

        found
      end
    end

    # Match one of many choices
    class Choices < ItemBase
      attr_reader :choices

      def initialize choices
        @choices = choices
      end

      def find data
        found = NOT_FOUND

        @choices.each do |choice|
          found = choice.find data
          if found != NOT_FOUND
            break
          end
        end

        found
      end

      # If any of the choices returns non-empty result, return that
      def find_all data
        found = []

        @choices.each do |choice|
          found.concat choice.find_all(data)
        end

        found
      end
    end

    class Type < ItemBase
      def find data
        case data
        when Gene::Types::Base
          data.type
        else
          Gene::Types::Symbol.new(data.class.to_s)
        end
      end

      def find_all data
        [find(data)]
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
