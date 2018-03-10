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
    "\"a \nmulti-line \nString\"" => "a \nmulti-line \nString",
    '"a"'      => "a",
    '1'        => 1,
    '-1'       => -1,
    '1.0'      => 1.0,
    '-1.0'     => -1.0,
    'true'     => true,
    'truea'    => Gene::Types::Symbol.new('truea'),
    'false'    => false,

    # Date
    # '2010-01-01'                      => false,
    # Date + hour + minute (local)
    # '2010-01-01T10:00'                => false,
    # Date + hour + minute (UTC)
    # '2010-01-01T10:00Z'               => false,
    # Date + hour + minute + second (local)
    # '2010-01-01T10:00:00'             => false,
    # Date + hour + minute + second (UTC)
    # '2010-01-01T10:00:00Z'            => false,
    # Date + hour + minute + second (Timezone is UTC+5)
    # '2010-01-01T10:00:00Z+5'          => false,
    # Date + hour + minute + second (Timezone is UTC-5)
    # '2010-01-01T10:00:00Z-05'         => false,
    # Date + hour + minute + second (Timezone is UTC-5)
    # '2010-01-01T10:00:00Z-05:00'      => false,
    # Date + hour + minute + second + fraction of second (Timezone is UTC-5)
    # '2010-01-01T10:00:00.123Z-05:00'  => false,

    'null'     => nil,
    'undefined'=> Gene::UNDEFINED,
    'void'     => Gene::UNDEFINED,
    '#_'       => Gene::PLACEHOLDER,
    # '#a'       => Gene::Types::Ref.new('a'),
    '\#'       => Gene::Types::Symbol.new('#', true),
    '\#a'      => Gene::Types::Symbol.new('#a', true),
    'a'        => Gene::Types::Symbol.new('a'),
    '#//'      => //,
    '#//mxi'   => //mxi,
    "#/\\n/"   => /\n/,
    # Quoted symbol, support escaping with "\"
    # '#""'      => Gene::Types::Symbol.new(''),
    # "#''"      => Gene::Types::Symbol.new(''),
    'a b'      => Gene::Types::Stream.new(Gene::Types::Symbol.new('a'), Gene::Types::Symbol.new('b')),
    '\\('      => Gene::Types::Symbol.new('(', true),
    '()'       => Gene::NOOP,
    '1 ()'     => Gene::Types::Stream.new(1, Gene::NOOP),
    '("a")'    => Gene::Types::Base.new("a"),
    '(a)'      => Gene::Types::Base.new(Gene::Types::Symbol.new('a')),
    '(a b)'    => Gene::Types::Base.new(Gene::Types::Symbol.new('a'), Gene::Types::Symbol.new('b')),
    '(#.. 1 2)'  => 1..2,
    '(#<> 1 2)'  => Set.new([1, 2]),

    # Below two should be handled by the parser
    # # line comment
    # #< comment out up to >#
    # Below two should be handled by the core interpreter
    # ## comment out next item (structural)
    # ##< comment out up to >## or end of group/array/hash (structural)
    # TODO need to add more tests espectially for structural comments
    "(a # b\n)"                   => Gene::Types::Base.new(Gene::Types::Symbol.new('a')),
    "(a #< this is a test ># b)"  => Gene::Types::Base.new(Gene::Types::Symbol.new('a'), Gene::Types::Symbol.new('b')),
    "(a #< this is a test)"       => Gene::Types::Base.new(Gene::Types::Symbol.new('a')),
    "(a ## b c)"                  => Gene::Types::Base.new(Gene::Types::Symbol.new('a'), Gene::COMMENT_NEXT, Gene::Types::Symbol.new('b'), Gene::Types::Symbol.new('c')),
    "(a ##(b))"                   => Gene::Types::Base.new(Gene::Types::Symbol.new('a'), Gene::COMMENT_NEXT, Gene::Types::Base.new(Gene::Types::Symbol.new('b'))),
    #"(a ##< b c)"                 => Gene::Types::Base.new(Gene::Types::Symbol.new('a')),
    #"(a ##< b >## c)"             => Gene::Types::Base.new(Gene::Types::Symbol.new('a'), Gene::Types::Symbol.new('c')),

    '(a (b))'  => Gene::Types::Base.new(Gene::Types::Symbol.new('a'), Gene::Types::Base.new(Gene::Types::Symbol.new('b'))),
    '[a]'      => [Gene::Types::Symbol.new('a')],
    '[^a]'     => [Gene::Types::Symbol.new('^a')],
    '[^^a]'    => [Gene::Types::Symbol.new('^^a')],
    #'(\[\] a)' => Gene::Types::Base.new(Gene::Types::Symbol.new('[]'), Gene::Types::Symbol.new('a')),
    '[[a]]'    => [[Gene::Types::Symbol.new('a')]],
  }.each do |input, result|
    it "parse #{input} should work" do
      Gene::Parser.parse(input).should == result
    end
  end

  it " # Additional test for single line comments
    (a
      #
      b
      # (
      # )
      c
    )
  " do
    result = Gene::Parser.parse(example.description)
    result.should == Gene::Types::Base.new(
      Gene::Types::Symbol.new('a'),
      Gene::Types::Symbol.new('b'),
      Gene::Types::Symbol.new('c'),
    )
  end

  describe "Hash" do
    it '{}' do
      result = Gene::Parser.parse(example.description)
      result.should == {}
    end

    it '{a : b}' do
      result = Gene::Parser.parse(example.description)
      result.keys.first.should == 'a'
      result.values.first.should == Gene::Types::Symbol.new('b')
    end

    it '{^a b}' do
      result = Gene::Parser.parse(example.description)
      result.keys.first.should == 'a'
      result.values.first.should == Gene::Types::Symbol.new('b')
    end

    it '{^^a}' do
      result = Gene::Parser.parse(example.description)
      result.keys.first.should == 'a'
      result.values.first.should == true
    end

    it '{^!a}' do
      result = Gene::Parser.parse(example.description)
      result.keys.first.should == 'a'
      result.values.first.should == false
    end

    ['{a : b c : d}', '{a : b, c : d}', '{,a : b, c : d,}'].each do |input|
      it input do
        result = Gene::Parser.parse(example.description)
        result.keys.should include('a')
        result.keys.should include('c')
        result.values.should include(Gene::Types::Symbol.new('b'))
        result.values.should include(Gene::Types::Symbol.new('d'))
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
      result.type.should == Gene::Types::Symbol.new('a')
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
      result.data[0].should == Gene::Types::Symbol.new('^key', true)
    end
  end

  # (#GENE ^version 1.0) sets the version of the document but does NOT insert anything in the document
  # (#GENE version) inserts the version into the document
  # (#GENE (do_this) (do_that) void) if the last value returns undefined, it'll not be inserted
  describe 'Processing instructions' do
    it '
      # Gene version the document conforms to. The parser must be able to parse. If not, throw error
      (#GENE ^version "1.0")
      123
    ' do
      result = Gene::Parser.parse(example.description)
      result.should == 123
    end

    it '
      (#GENE ^version "1.0")
      (#GENE version)
    ' do
      result = Gene::Parser.parse(example.description)
      result.should == "1.0"
    end

    it '
      # Default version is 1.0
      (#GENE version)
    ' do
      result = Gene::Parser.parse(example.description)
      result.should == "1.0"
    end
  end

  # An optional readonly environment hash is passed in to the parser
  # By default it'll be the environment a process is attached to
  # However a custom environment can be passed in too
  describe 'Environment' do
    it '(#ENV "USER")' do
      result = Gene::Parser.parse(example.description)
      result.should == ENV['USER']
    end

    it '(#ENV "test")' do
      env = {'test' => 123}
      result = Gene::Parser.parse(example.description, 'env' => env)
      result.should == env['test']
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
    '"',
    "'",
    '("',
    "('",
    '(a',
    "(a # b)",
    "(a ^b",
    '{',
    '{a',
    '{a :',
    '{a : b',
    '[',
    '[a',
  ].each do |input|
    it "process #{input.inspect} should fail with PrematureEndError" do
      lambda {
        Gene::Parser.parse(input)
      }.should raise_error(Gene::PrematureEndError)
    end
  end
end
