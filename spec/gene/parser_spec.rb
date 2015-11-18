require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  # Copy individual tests to below and run to make debug easier
  # in vim command line, enter :rspec %:11
  {
  }.each do |input, result|
    it "TEMP TEST should work" do
      Gene::Parser.parse(input).should == result
    end
  end

  {
    ''         => Gene::Stream.new,
    '"a double-quoted String"' => "a double-quoted String",
    "'a single-quoted String'" => "a single-quoted String",
    '"a"'      => "a",
    '1'        => 1,
    '-1'       => -1,
    '1.0'      => 1.0,
    '-1.0'     => -1.0,
    'true'     => true,
    'false'    => false,
    'null'     => nil,
    '#_'       => Gene::Types::Placeholder,
    'a'        => Gene::Types::Ident.new('a'),
    'a b'      => Gene::Stream.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
    '\\('      => Gene::Types::Ident.new('('),
    '()'       => Gene::NOOP,
    '1 ()'     => Gene::Stream.new(1, Gene::NOOP),
    '("a")'    => Gene::Types::Group.new("a"),
    '(a)'      => Gene::Types::Group.new(Gene::Types::Ident.new('a')),
    '(a b)'    => Gene::Types::Group.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
    # '#' denotes single line comment
    "(a # b\n)"     => Gene::Types::Group.new(Gene::Types::Ident.new('a')),
    # '##' denotes comment to end of group or next ##> in same group
    # TODO need to add more tests espectially for nested ()[]{} etc
    # TODO still need a way to comment out stuff without worrying about structure
    "(a ## b)"      => Gene::Types::Group.new(Gene::Types::Ident.new('a')),
    "(a ## b ##> c)"=> Gene::Types::Group.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('c')),
    '(a (b))'  => Gene::Types::Group.new(Gene::Types::Ident.new('a'), Gene::Types::Group.new(Gene::Types::Ident.new('b'))),
    '[a]'      => Gene::Types::Group.new(Gene::Types::Ident.new('[]'), Gene::Types::Ident.new('a')),
    '(\[\] a)' => Gene::Types::Group.new(Gene::Types::Ident.new('[]'), Gene::Types::Ident.new('a')),
    '[[a]]'    => Gene::Types::Group.new(Gene::Types::Ident.new('[]'), Gene::Types::Group.new(Gene::Types::Ident.new('[]'), Gene::Types::Ident.new('a'))),
    '{}'       => Gene::Types::Group.new(Gene::Types::Ident.new('{}')),
    '(\{\})'   => Gene::Types::Group.new(Gene::Types::Ident.new('{}')),
    '{a : b}'  => Gene::Types::Group.new(Gene::Types::Ident.new('{}'), Gene::Types::Pair.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b'))),
    '{a : b c : d}' => Gene::Types::Group.new(Gene::Types::Ident.new('{}'), 
                                       Gene::Types::Pair.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
                                       Gene::Types::Pair.new(Gene::Types::Ident.new('c'), Gene::Types::Ident.new('d'))
                                      ),
    '{a : b, c : d}' => Gene::Types::Group.new(Gene::Types::Ident.new('{}'), 
                                       Gene::Types::Pair.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
                                       Gene::Types::Pair.new(Gene::Types::Ident.new('c'), Gene::Types::Ident.new('d'))
                                      ),
  }.each do |input, result|
    it "parse #{input} should work" do
      Gene::Parser.parse(input).should == result
    end
  end

  [
    '(',
    ')',
    '(a',
    '[(]',
    '[)]',
    '{:}',
    '{a}',
    '{a b}',
    '{a :}',
    "(a # b)",
  ].each do |input|
    it "process #{input} should fail" do
      lambda {
        Gene::Parser.parse(input)
      }.should raise_error(Gene::ParseError)
    end
  end
end
