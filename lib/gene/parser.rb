require 'treetop'
require 'gene/grammar'

module Gene
  class Parser
    def initialize
      @grammar = Gene::GrammarParser.new
    end

    def parse input
      @grammar.parse(input)
    end
  end
end

