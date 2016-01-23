require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::ExperimentalInterpreter do
  before do
    @interpreter = Gene::ExperimentalInterpreter.new
  end

  {
    '(1 + 1)'           => 2,
    '1 + 1'             => 2,
    '1 + 1 + 1'         => 3,
    '1 * 2'             => 2,
    '1 + 2 * 3 + 4'     => 11,
    '1 + 2 * (3 + 4)'   => 15,
    '(1 + 2) * 3'       => 9,
  }.each do |input, expected|
    it input do
      @interpreter.parse_and_process(input).should == expected
    end
  end
end

