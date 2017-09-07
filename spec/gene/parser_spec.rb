require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  # Copy individual tests to below and run to make debug easier
  # in vim command line, enter :rspec %:11
  {
  }.each do |input, result|
    it "debugging #{input}" do
      Gene::Parser.parse(input).should == result
    end
  end

  {
    ''         => Gene::Types::Stream.new,
    '"a double-quoted String"' => "a double-quoted String",
    "'a single-quoted String'" => "a single-quoted String",
    # TODO: "\"a \nmulti-line \nString\"" => "a \nmulti-line \nString",
    '"a"'      => "a",
    '1'        => 1,
    '-1'       => -1,
    '1.0'      => 1.0,
    '-1.0'     => -1.0,
    'true'     => true,
    'truea'    => Gene::Types::Ident.new('truea'),
    'false'    => false,
    'null'     => nil,
    'undefined'=> Gene::UNDEFINED,
    '#_'       => Gene::PLACEHOLDER,
    # '#a'       => Gene::Types::Ref.new('a'),
    '\#'       => Gene::Types::Ident.new('#', true),
    '\#a'      => Gene::Types::Ident.new('#a', true),
    'a'        => Gene::Types::Ident.new('a'),
    # Quoted identity, support escaping with "\"
    # '#""'      => Gene::Types::Ident.new(''),
    # "#''"      => Gene::Types::Ident.new(''),
    'a b'      => Gene::Types::Stream.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
    '\\('      => Gene::Types::Ident.new('(', true),
    '()'       => Gene::NOOP,
    '1 ()'     => Gene::Types::Stream.new(1, Gene::NOOP),
    '("a")'    => Gene::Types::Base.new("a"),
    '(a)'      => Gene::Types::Base.new(Gene::Types::Ident.new('a')),
    '(a b)'    => Gene::Types::Base.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
    '(#.. 1 2)'  => 1..2,
    '(#<> 1 2)'  => Set.new([1, 2]),

    # Below two should be handled by the parser
    # # line comment
    # #< comment out up to >#
    # Below two should be handled by the core interpreter
    # ## comment out next item (structural)
    # ##< comment out up to >## or end of group/array/hash (structural)
    # TODO need to add more tests espectially for structural comments
    "(a # b\n)"                   => Gene::Types::Base.new(Gene::Types::Ident.new('a')),
    "(a #< this is a test ># b)"  => Gene::Types::Base.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('b')),
    "(a #< this is a test)"       => Gene::Types::Base.new(Gene::Types::Ident.new('a')),
    "(a ## b c)"                  => Gene::Types::Base.new(Gene::Types::Ident.new('a'), Gene::COMMENT_NEXT, Gene::Types::Ident.new('b'), Gene::Types::Ident.new('c')),
    "(a ##(b))"                   => Gene::Types::Base.new(Gene::Types::Ident.new('a'), Gene::COMMENT_NEXT, Gene::Types::Base.new(Gene::Types::Ident.new('b'))),
    #"(a ##< b c)"                 => Gene::Types::Base.new(Gene::Types::Ident.new('a')),
    #"(a ##< b >## c)"             => Gene::Types::Base.new(Gene::Types::Ident.new('a'), Gene::Types::Ident.new('c')),

    '(a (b))'  => Gene::Types::Base.new(Gene::Types::Ident.new('a'), Gene::Types::Base.new(Gene::Types::Ident.new('b'))),
    '[a]'      => [Gene::Types::Ident.new('a')],
    #'(\[\] a)' => Gene::Types::Base.new(Gene::Types::Ident.new('[]'), Gene::Types::Ident.new('a')),
    '[[a]]'    => [[Gene::Types::Ident.new('a')]],
  }.each do |input, result|
    it "parse #{input} should work" do
      Gene::Parser.parse(input).should == result
    end
  end

  describe "Hash" do
    it '{}' do
      result = Gene::Parser.parse(example.description)
      result.should == {}
    end

    it '{a : b}' do
      result = Gene::Parser.parse(example.description)
      result.keys.first.should == Gene::Types::Ident.new('a')
      result.values.first.should == Gene::Types::Ident.new('b')
    end

    ['{a : b c : d}', '{a : b, c : d}', '{,a : b, c : d,}'].each do |input|
      it input do
        result = Gene::Parser.parse(example.description)
        result.keys.should include(Gene::Types::Ident.new('a'))
        result.keys.should include(Gene::Types::Ident.new('c'))
        result.values.should include(Gene::Types::Ident.new('b'))
        result.values.should include(Gene::Types::Ident.new('d'))
      end
    end
  end

  describe "properties" do
    it '(a ^key true)' do
      result = Gene::Parser.parse(example.description)
      result.class.should == Gene::Types::Base
      result.properties['key'].should == true
    end

    it '(^key true a)' do
      result = Gene::Parser.parse(example.description)
      result.class.should == Gene::Types::Base
      result.type.should == Gene::Types::Ident.new('a')
      result.properties['key'].should == true
    end

    it '(prop x ^a [1] ^b [1 2])' do
      result = Gene::Parser.parse(example.description)
      result.properties['a'].should == [1]
      result.properties['b'].should == [1, 2]
    end

    # Alternative syntax: ^^key = ^+key, ^!key = ^-key
    it '(a ^^key)' do
      result = Gene::Parser.parse(example.description)
      result.class.should == Gene::Types::Base
      result.properties['key'].should == true
    end

    it '(^^key a)' do
      result = Gene::Parser.parse(example.description)
      result.class.should == Gene::Types::Base
      result.properties['key'].should == true
    end

    it '(a ^+key)' do
      result = Gene::Parser.parse(example.description)
      result.class.should == Gene::Types::Base
      result.properties['key'].should == true
    end

    it '(a ^!key)' do
      result = Gene::Parser.parse(example.description)
      result.class.should == Gene::Types::Base
      result.properties['key'].should == false
    end

    it '(a ^-key)' do
      result = Gene::Parser.parse(example.description)
      result.class.should == Gene::Types::Base
      result.properties['key'].should == false
    end

    it '(a \^key)' do
      result = Gene::Parser.parse(example.description)
      result.class.should == Gene::Types::Base
      result.data[0].should == Gene::Types::Ident.new('^key', true)
    end
  end

  describe 'Processing instructions' do
    it '
      # Gene version the document conforms to. The parser must be able to parse. If not, throw error
      (#GENE ^version 1.0)
    ' do
      pending
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
    '{##}',
    '{## : b}',
    '{a : ##}',
    '{a :}',
    "(a # b)",
    "(a ^b)",
  ].each do |input|
    it "process #{input} should fail" do
      lambda {
        Gene::Parser.parse(input)
      }.should raise_error(Gene::ParseError)
    end
  end

  [
    '(',
    '(a',
    "(a # b)",
    "(a ^b",
    '{',
    '{a',
    '{a :',
    '{a : b',
  ].each do |input|
    it "process #{input.inspect} should fail with PrematureEndError" do
      pending
      lambda {
        Gene::Parser.parse(input)
      }.should raise_error(Gene::PrematureEndError)
    end
  end
end
