require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Interpreter do
  {
    '1'      => 1,
    '"a"'    => "a",
    'null'   => nil,
    '[]'     => [],
    '[1]'    => [1],
    '{}'     => {},
    '{1 2}'  => {1 => 2},
    '()'     => Gene::NOOP,
    '[()]'   => [],
    '(1)'    => 1,
    '(1, 2)' => 2,
    #'(($$ let a 1) ($$ + a 1))' => 2,
  }.each do |input, result|
    it "process #{input} should work" do
      parsed = Gene::Parser.new(input).parse
      Gene::Interpreter.new.run(parsed).should == result
    end
  end
end
