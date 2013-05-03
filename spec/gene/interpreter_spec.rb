require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Interpreter do
  {
    '(1)' => 1,
    '((1))' => 1,
    '(($$set a 1) (a + 1))' => 2,
  }.each do |input, result|
    it "process #{input} should work" do
      parsed = Gene::Parser.new(input).parse
      Gene::Interpreter.new(parsed).run.should == result
    end
  end
end
