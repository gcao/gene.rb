require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::GeneMacroInterpreter do
  before do
    @interpreter = Gene::GeneMacroInterpreter.new
  end

  it "(#def a 'a')" do
    result = @interpreter.parse_and_process(example.description)
  end
end
