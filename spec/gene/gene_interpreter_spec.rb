require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::GeneInterpreter do
  before do
    @interpreter = Gene::GeneInterpreter.new
  end

  it "(class A)" do
    result = @interpreter.parse_and_process(example.description)
    result.class.should == Gene::Lang::Class
    result.name.should  == 'A'
  end

end
