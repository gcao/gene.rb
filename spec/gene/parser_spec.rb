require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  # Copy individual tests to below and run to make debug easier
  # in vim command line, enter :rspec %:11
  {
    #'($ a b)'    => Gene::Group.new(Gene::Entity.new('[]'), Gene::Pair.new(Gene::Entity.new('a'), Gene::Entity.new('b'))),
  }.each do |input, result|
    it "TEMP TEST should work" do
      Gene::Parser.new(input).parse.should == result
    end
  end

  {
    ''         => Gene::Stream.new,
    '""'       => "",
    '"a"'      => "a",
    '1'        => 1,
    '-1'       => -1,
    '1.0'      => 1.0,
    '-1.0'     => -1.0,
    'true'     => true,
    'false'    => false,
    'null'     => nil,
    'a'        => Gene::Entity.new('a'),
    'a b'      => Gene::Stream.new(Gene::Entity.new('a'), Gene::Entity.new('b')),
    '\\('      => Gene::Entity.new('('),
    '()'       => Gene::NOOP,
    '1 ()'     => Gene::Stream.new(1, Gene::NOOP),
    '("a")'    => Gene::Group.new("a"),
    '(a)'      => Gene::Group.new(Gene::Entity.new('a')),
    '(a b)'    => Gene::Group.new(Gene::Entity.new('a'), Gene::Entity.new('b')),
    '(a (b))'  => Gene::Group.new(Gene::Entity.new('a'), Gene::Group.new(Gene::Entity.new('b'))),
    '[a]'      => Gene::Group.new(Gene::Entity.new('[]'), Gene::Entity.new('a')),
    '(\[\] a)' => Gene::Group.new(Gene::Entity.new('[]'), Gene::Entity.new('a')),
    '[[a]]'    => Gene::Group.new(Gene::Entity.new('[]'), Gene::Group.new(Gene::Entity.new('[]'), Gene::Entity.new('a'))),
    '{}'       => Gene::Group.new(Gene::Entity.new('{}')),
    '(\{\})'   => Gene::Group.new(Gene::Entity.new('{}')),
    '{a : b}'  => Gene::Group.new(Gene::Entity.new('{}'), Gene::Pair.new(Gene::Entity.new('a'), Gene::Entity.new('b'))),
    '{a : b c : d}' => Gene::Group.new(Gene::Entity.new('{}'), 
                                       Gene::Pair.new(Gene::Entity.new('a'), Gene::Entity.new('b')),
                                       Gene::Pair.new(Gene::Entity.new('c'), Gene::Entity.new('d'))
                                      ),
    '{a : b, c : d}' => Gene::Group.new(Gene::Entity.new('{}'), 
                                       Gene::Pair.new(Gene::Entity.new('a'), Gene::Entity.new('b')),
                                       Gene::Pair.new(Gene::Entity.new('c'), Gene::Entity.new('d'))
                                      ),
  }.each do |input, result|
    it "parse #{input} should work" do
      Gene::Parser.new(input).parse.should == result
    end
  end

  [
    '(',
    ')',
    '[(]',
    '[)]',
    '{:}',
    '{a}',
    '{a b}',
    '{a :}',
  ].each do |input|
    it "process #{input} should fail" do
      lambda {
        Gene::Parser.new(input).parse
      }.should raise_error(Gene::ParseError)
    end
  end
end
