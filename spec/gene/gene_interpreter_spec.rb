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

  it "(fn doSomething)" do
    result = @interpreter.parse_and_process(example.description)
    result.class.should == Gene::Lang::Function
    result.name.should  == 'doSomething'
  end

  it "(class A (fn doSomething))" do
    result = @interpreter.parse_and_process(example.description)
    result.class.should == Gene::Lang::Class
    result.name.should  == 'A'
    result.block.size.should == 1
    stmt1 = result.block[0]
    stmt1.class.should == Gene::Lang::Function
    stmt1.name.should == 'doSomething'
  end
end
