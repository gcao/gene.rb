require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::CoreInterpreter do

  # Reserved: #[A-Z]+, #//[a-z]* (regular expression + flags), #["'.,/].*, #[any special characters]
  # E.g. #IF #FOR #ENV

  # Copy individual tests to below and process to make debug easier
  # in vim command line, enter :!rspec %:20
  {
    '(#.. 1 3)'   => Range.new(1, 3),
  }.each do |input, result|
    it "process #{input} should work !!!" do
      parsed = Gene::Parser.new(input).parse
      Gene::CoreInterpreter.new.process(parsed).should == result
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
    '(#.. 1 3)'  => Range.new(1, 3),
    #'(#|| 1 2)'  => Gene::Types::Tuple.new(1, 2),
    '(#"" 1 3)'  => Gene::Types::ComplexString.new(1, 3),
    '(#// a|b)'  => Regexp.new('a|b'),
    '(#//i a|b)' => Regexp.new('a|b', Regexp::IGNORECASE),
    "(#BASE64 \"VGhpcyBpcyBhIHRlc3Q=\")" => Gene::Types::Base64.new("VGhpcyBpcyBhIHRlc3Q=")
  }.each do |input, expected|
    it input do
      Gene::CoreInterpreter.parse_and_process(input).should == expected
    end
  end

  describe "references" do
    it '[(#a)]' do # Reference that is not initialized defaults to nil/null
      pending
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [nil]
    end

    it '[(#SET a 1) (#a)]' do
      pending
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [1, 1]
    end

    it '[(#SET a 1) #a]' do
      pending
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [1, 1]
    end

    it '[(#SET a 1 ()) #a]' do
      pending
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [1]
    end

    it '[(#SET a 1 ()) #a (#UNSET a) #a]' do
      pending
      result = Gene::CoreInterpreter.parse_and_process(example.description)
      result.should == [1, nil]
    end
  end

  describe "Interpreter capabiliby check" do
    #it '(#SUPPORT? #SET #THROW "#SET is not supported")' do
    it '(#SUPPORT? (#SET) (#THROW "not supported"))' do
      pending "Not sure whether this is a good idea"
      lambda {
        Gene::CoreInterpreter.parse_and_process(example.description)
      }.should_not raise_error
    end
  end

end
