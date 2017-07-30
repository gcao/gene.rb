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

  it "(fn doSomething a)" do
    result = @interpreter.parse_and_process(example.description)
    result.class.should == Gene::Lang::Function
    result.name.should  == 'doSomething'
    result.args.size.should == 1
    result.args[0].should   == Gene::Lang::Argument.new('a')
  end

  it "(let a 'value')" do
    result = @interpreter.parse_and_process(example.description)
    result.class.should == Gene::Lang::Variable
    result.name.should  == 'a'
    result.value.should == 'value'
  end

  it "(let a (1 + 2))" do
    result = @interpreter.parse_and_process(example.description)
    result.class.should == Gene::Lang::Variable
    result.name.should  == 'a'
    result.value.should == 3
  end

  it "(class A (fn doSomething))" do
    result = @interpreter.parse_and_process(example.description)
    result.class.should      == Gene::Lang::Class
    result.name.should       == 'A'
    result.block.size.should == 1
    stmt1 = result.block[0]
    stmt1.class.should == Gene::Lang::Function
    stmt1.name.should  == 'doSomething'
  end

  it "(1 + 2)" do
    result = @interpreter.parse_and_process(example.description)
    result.should == 3
  end

  it "(let a 1) (a + 2)" do
    result = @interpreter.parse_and_process(example.description)
    result.should == 3
  end
end
