require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

$logger = Logem::Logger.new ''

describe 'gene/grammar.tt' do
  # Copy individual tests to below and run to make debug easier
  # in vim command line, enter :rspec %:11
  {
    '""'    => '',
  }.each do |input, result|
    it "TEMP TEST should work" do
      parser = Gene::GrammarParser.new
      nodes = parser.parse(input)
      $logger.level = Logem::DEBUG
      nodes.resolve.should == result
    end
  end

  {
    #'1'    => 1,
    #'-1.1'    => -1.1,
    #'""'    => '',
    #'a'    => Gene::Entity.new('a'),
    #'true'    => true,
    #'null'    => nil,
    #'()'    => Gene::NOOP,
    #'(a)'    => Gene::Group.new(Gene::Entity.new('a')),
  }.each do |input, result|
    it "parse #{input} should work" do
      parser = Gene::GrammarParser.new
      nodes = parser.parse(input)
      nodes.resolve.should == result
    end
  end
end
