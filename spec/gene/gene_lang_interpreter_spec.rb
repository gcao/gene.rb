require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'gene/lang/interpreter'

describe Gene::Lang::Interpreter do
  before do
    @interpreter = Gene::Lang::Interpreter.new
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

    it "(class A (method doSomething))" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Class
      result.name.should  == 'A'
      result.instance_methods.size.should == 1
    end

    it "(class A (init a (let @a a))) (new A 1)" do
      result = @interpreter.parse_and_process(example.description)
      result['a'].should == 1
    end

    it "
      (class A
        (init [a] (let @a a))
        (method add num (@a + num))
      )
      (let a (new A 1))
      (a .add 2)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end

  describe "properties" do
    it "
      (class A
        (prop x
          ^get [@x]
          ^set [value (let @x value)]
        )
      )
      (let a (new A))
      (a .x= 'value')
      (a .x)
    " do
      result = Gene::Parser.parse(example.description)
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "
      (class A (prop x))
      (let a (new A))
      (a .x= 'value')
      (a .x)
    " do
      result = Gene::Parser.parse(example.description)
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end
  end

  describe "fn" do
    it "(fn doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
    end

    it "(^^inherit_scope fn doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.inherit_scope.should == true
    end

    it "(fn doSomething a)" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.block.arguments.size.should == 1
      result.block.arguments[0].should   == Gene::Lang::Argument.new(0, 'a')
    end

    it "(fn doSomething [] '1')(doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == '1'
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

  describe "if" do
    it "(if true 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(if true [(let a 1)(a + 2)] 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    it "(if false 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end

    it "(if false 1 [(let a 1)(a + 2)])" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end
end
