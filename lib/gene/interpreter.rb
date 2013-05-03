module Gene
  class Interpreter
    def initialize data
      @data = data
    end

    def run_partial data
      case data
      when Group
        run_group data
      when Entity
        data
      #when Array
      #  data.map {|item| run_partial item }
      #when Hash
      #  data
      else
        data
      end
    end

    def run_group group
      return Gene::NOOP if group.children.empty?

      case group.first
      when Entity.new('[]')
        group.rest
      when Entity.new('{}')
        Hash[*group.rest]
      end
    end

    def run
      run_partial @data
    end
  end
end

