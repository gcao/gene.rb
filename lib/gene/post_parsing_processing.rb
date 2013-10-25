module Gene
  module PostParsingProcessing
    def parse *args
      $logger and $logger.debug 'PostParsingProcessing#parse'
      super
    end

    GrammarParser.send :include, self
  end
end

