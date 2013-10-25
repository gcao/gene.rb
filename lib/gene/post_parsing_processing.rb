module Gene
  module PostParsingProcessing
    def parse *args
      $logger and $logger.debug 'PostParsingProcessing#parse'
      normalize_result super.resolve
    end

    private

    def normalize_result result
      case result
      when Group
        result
      when Pairs
        result
      when Array
        result
      else
        result
      end
    end

    GrammarParser.send :include, self
  end
end

