require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::TypesInterpreter do

  # Copy individual tests to below and process to make debug easier
  # in vim command line, enter :!rspec %:20
  {
    #'(($$ let a 1) ($$ + a 1))' => 2,
  }.each do |input, result|
    it "process #{input} should work !!!" do
      parsed = Gene::Parser.new(input).parse
      @interpreter.process(parsed).should == result
    end
  end

  {
    '1'          => 1,
    '"a"'        => "a",
    'null'       => nil,
    '[]'         => [],
    '[1]'        => [1],
    '{}'         => {},
    '{1 : 2}'    => {1 => 2},
    '{() : 2}'   => {},
    '()'         => Gene::NOOP,
    '[()]'       => [],
    '(.. 1 3)'   => Range.new(1, 3),
    '("" 1 3)'   => Gene::Types::ComplexString.new(1, 3),
    "(base64 \"VGhpcyBpcyBhIHRlc3Q=\")" => Gene::Types::Base64.new("VGhpcyBpcyBhIHRlc3Q=")
    #'(($$ let a 1) ($$ + a 1))' => 2,
  }.each do |input, expected|
    it input do
      Gene::TypesInterpreter.parse_and_process(input).should == expected
    end
  end

  describe "metadata" do
    it '(a (^b))' do
      result = Gene::TypesInterpreter.parse_and_process(example.description)
      result.class.should == Gene::Types::Group
      result.metadata['b'].should == true
    end

    it '(a (^b 1))' do
      result = Gene::TypesInterpreter.parse_and_process(example.description)
      result.class.should == Gene::Types::Group
      result.metadata['b'].should == 1
    end
  end

  describe "references" do
    it '[(#a 1) (#a)]' do
      result = Gene::TypesInterpreter.parse_and_process(example.description)
      result.should == [1, 1]
    end

    it '[(#a 1 ()) (#a)]' do
      result = Gene::TypesInterpreter.parse_and_process(example.description)
      result.should == [1]
    end
  end

end
