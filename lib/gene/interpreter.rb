module Gene
  class Interpreter
    def initialize data
      @data = data
    end

    def run_partial data
      case data
      when Array
        data
      when Hash
        data
      else
        data
      end
    end

    def run
      run_partial @data
    end
  end
end

