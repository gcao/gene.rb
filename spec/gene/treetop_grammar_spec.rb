require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

$logger = Logem::Logger.new ''

module Gene
  describe 'gene/grammar.tt' do
    # Copy individual tests to below and run to make debug easier
    # in vim command line, enter :rspec %:11
    {
      '{a : b}' => Pairs.new(Pair.new(Entity.new('a'), Entity.new('b'))),
    }.each do |input, result|
      it "TEMP TEST should work" do
        parser = GrammarParser.new
        nodes = parser.parse(input)
        $logger.level = Logem::DEBUG
        nodes.resolve.should == result
        $logger.level = Logem::INFO
      end
    end

    {
      '1'       => 1,
      '-1.1'    => -1.1,
      '""'      => '',
      '"a"'     => 'a',
      'true'    => true,
      'false'   => false,
      'null'    => nil,
      'a'       => Entity.new('a'),
      '()'      => NOOP,
      '(a)'     => Group.new(Entity.new('a')),
      '(a b)'   => Group.new(Entity.new('a'), Entity.new('b')),
      '[]'      => [],
      '[a b]'   => [Entity.new('a'), Entity.new('b')],
      '{}'      => Pairs.new,
      '{a : b}' => Pairs.new(Pair.new(Entity.new('a'), Entity.new('b'))),
    }.each do |input, result|
      it "parse #{input} should work" do
        parser = GrammarParser.new
        nodes = parser.parse(input)
        nodes.resolve.should == result
      end
    end
  end
end

