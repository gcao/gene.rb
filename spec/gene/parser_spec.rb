require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  # Copy individual tests to below and run to make debug easier
  # in vim command line, enter :rspec %:11
  {
  }.each do |input, result|
    it "TEMP TEST should work" do
      Gene::Parser.new(input).parse.should == result
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
    'a'        => Gene::Types::Ident.new('a'),
    'a b'      => Gene::Stream.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
    '\\('      => Gene::Types::Ident.new('('),
    '()'       => Gene::NOOP,
    '1 ()'     => Gene::Stream.new(1, Gene::NOOP),
    '("a")'    => Gene::Types::Group.new("a"),
    '(a)'      => Gene::Types::Group.new(Gene::Types::Ident.new('a')),
    '(a b)'    => Gene::Types::Group.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
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
