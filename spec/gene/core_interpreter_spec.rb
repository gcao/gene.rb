require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::CoreInterpreter do

  # Reserved: #[A-Z]+, #//[a-z]* (regular expression + flags), #["'.,/].*, #[any special characters]
  # E.g. #IF #FOR #ENV

  # Copy individual tests to below and process to make debug easier
  # in vim command line, enter :!rspec %:20
  {
  }.each do |input, result|
    it "process #{input} should work !!!" do
      parsed = Gene::Parser.new(input).parse
      @interpreter.process(parsed).should == result
    end
  end

  {
    '1'          => 1,
    '"a"'        => "a",
    "'a'"        => "a",
    'null'       => nil,
    '[]'         => [],
    '[1]'        => [1],
    '{}'         => {},
    '{1 : 2}'    => {1 => 2},
    '{() : 2}'   => {},
    '()'         => Gene::NOOP,
    '[()]'       => [],
    '(#.. 1 3)'   => Range.new(1, 3),
    '(#"" 1 3)'   => Gene::Types::ComplexString.new(1, 3),
    '(#// a|b)'  => Regexp.new('a|b'),
    '(#//i a|b)' => Regexp.new('a|b', Regexp::IGNORECASE),
    "(#BASE64 \"VGhpcyBpcyBhIHRlc3Q=\")" => Gene::Types::Base64.new("VGhpcyBpcyBhIHRlc3Q=")
  }.each do |input, expected|
    it input do
      Gene::CoreInterpreter.parse_and_process(input).should == expected
    end
  end

  describe "metadata" do
    it '(a (^b))' do
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.class.should == Gene::Types::Group
      result.metadata['b'].should == true
    end

    it '(a (^b 1))' do
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.class.should == Gene::Types::Group
      result.metadata['b'].should == 1
    end
  end

  describe "references" do
    it '[(#a 1) (#a)]' do
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [1, 1]
    end

    it '[(#SET a 1) (#a)]' do
      pending
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [1]
    end

    it '[(#UNSET a)]' do
      pending
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == []
    end

    it '[(#a 1 ()) #a]' do
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [1]
    end

    it '[(#a 1 ()) (#a)]' do
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [1]
    end
  end

end
