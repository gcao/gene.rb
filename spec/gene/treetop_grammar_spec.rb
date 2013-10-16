require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'gene/grammar.tt' do
  # Copy individual tests to below and run to make debug easier
  # in vim command line, enter :rspec %:11
  {
    '()'    => Gene::NOOP,
  }.each do |input, result|
    it "TEMP TEST should work" do
      parser = Gene::GrammarParser.new
      nodes = parser.parse(input)
      nodes.resolve.should == result
    end
  end
end
