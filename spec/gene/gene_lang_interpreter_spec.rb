require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::GeneLangInterpreter do
  before do
    @interpreter = Gene::GeneLangInterpreter.new
  end

  describe "class" do
    it "(class A)" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Class
      result.name.should  == 'A'
    end

    it "(class A)(new A)" do
      result = @interpreter.parse_and_process(example.description)
      result.class.class.should == Gene::Lang::Class
      result.class.name.should  == 'A'
    end

    it "(class A (fn doSomething))" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should      == Gene::Lang::Class
      result.name.should       == 'A'
      result.block.statements.size.should == 1
      stmt1 = result.block[0]
      stmt1.class.should == Gene::Lang::Function
      stmt1.name.should  == 'doSomething'
    end
  end

  describe "fn" do
    it "(fn doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
    end

    it "(fn doSomething a)" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.block.arguments.size.should == 1
      result.block.arguments[0].should   == Gene::Lang::Argument.new(0, 'a')
    end

    it "(fn doSomething a '1')" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.block.arguments.size.should == 1
      result.block.arguments[0].should   == Gene::Lang::Argument.new(0, 'a')
      result.block.statements.first.should == '1'
    end

    it "(fn doSomething a a)(doSomething '1')" do
      result = @interpreter.parse_and_process(example.description)
      result.should == '1'
    end

    it "(fn doSomething [a b] (a + b))(doSomething 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end

  describe "Binary expression" do
    it "(1 + 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end

  describe "variable definition" do
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

    it "(let a 1) (a + 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    it "(let a 1) (let b 2) (a + b)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end
end
