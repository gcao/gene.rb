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
    #'(($$ let a 1) ($$ + a 1))' => 2,
  }.each do |input, result|
    it input do
      Gene::TypesInterpreter.parse_and_process(input).should == result
    end
  end

  it "(base64 \"VGhpcyBpcyBhIHRlc3Q=\")" do
    result = Gene::TypesInterpreter.parse_and_process(example.description)
    result.class.should == Gene::Types::Base64
    result.data.should == "VGhpcyBpcyBhIHRlc3Q="
  end

end
