require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Lang::Interpreter do
  before do
    @interpreter = Gene::Lang::Interpreter.new
  end

  describe "special built-in variables and functions" do
    it "_context" do
      result = @interpreter.parse_and_process("
        (let a 1)
        _context
      ")
      result.scope.get_variable('a').should == 1
    end

    it "_global" do
      result = @interpreter.parse_and_process("
        (_invoke _global 'get_variable' 'Array')
      ")
      result.name.should == "Array"
    end

    it "_scope" do
      result = @interpreter.parse_and_process("
        (let a 1)
        _scope
      ")
      result.get_variable('a').should == 1
    end

    it "_invoke" do
      result = @interpreter.parse_and_process("
        (let a 1)
        (_invoke _scope 'get_variable' 'a')
      ")
      result.should == 1
    end

    it "_arguments" do
      result = @interpreter.parse_and_process("
        (fn f [] _arguments)
        (f 1 2)
      ")
      result.should == [1, 2]
    end

    it "_self" do
      result = @interpreter.parse_and_process("
        (class A
          (method f [] _self)
        )
        (let a (new A))
        (a .f)
      ")
      result.class.name.should == 'A'
    end
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
        (init a
          (let @a a)
        )
        (method incr-a []
          (let @a (@a + 1))
        )
        (method test num
          (.incr-a)
          (@a + num)
        )
      )
      (let a (new A 1))
      (a .test 2)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 4
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

  describe "cast" do
    it "
      (class A)
      (class B)
      (let a (new A))
      (cast a B)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.class.class.should == Gene::Lang::Class
      result.class.name.should  == 'B'
    end

    it "
      (class A)
      (class B (method test [] 'B#test'))
      (let a (new A))
      ((cast a B) .test)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should  == 'B#test'
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
      result.arguments.size.should == 1
      result.arguments[0].index.should == 0
      result.arguments[0].name.should == 'a'
    end

    it "(fn doSomething [] '1')(doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == '1'
    end

    it "(fn doSomething [] '1')(doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == '1'
    end

    it "(fn doSomething a '1')" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.arguments.size.should == 1
      result.arguments[0].index.should == 0
      result.arguments[0].name.should == 'a'
      result.statements.first.should == '1'
    end

    it "(fn doSomething a a)(doSomething '1')" do
      result = @interpreter.parse_and_process(example.description)
      result.should == '1'
    end

    it "(fn doSomething [a b] (a + b))(doSomething 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    it "
      (fn f [] (.x))
      (class A (method x [] 'value'))
      (let a (new A))
      (call f a)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "
      (let a 1)
      (fn f b (a + b))
      (f 2)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end

  describe "def vs let" do
    it "
      (def x 0)
      (fn f [] (def x 1))
      (f)
      x
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 0
    end

    it "
      (let x 0)
      (fn f [] (let x 1))
      (f)
      x
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end

  describe "fnx" do
    it "
      (let f (fnx [] 1))
      (f)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "
      ((fnx [] 1))
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end

  describe "Comparison" do
    it("(1 < 2)")  { @interpreter.parse_and_process(example.description).should == true }
    it("(2 < 2)")  { @interpreter.parse_and_process(example.description).should == false }
    it("(3 < 2)")  { @interpreter.parse_and_process(example.description).should == false }
    it("(1 <= 2)") { @interpreter.parse_and_process(example.description).should == true }
    it("(2 <= 2)") { @interpreter.parse_and_process(example.description).should == true }
    it("(3 <= 2)") { @interpreter.parse_and_process(example.description).should == false }
    it("(1 > 2)")  { @interpreter.parse_and_process(example.description).should == false }
    it("(2 > 2)")  { @interpreter.parse_and_process(example.description).should == false }
    it("(3 > 2)")  { @interpreter.parse_and_process(example.description).should == true }
    it("(1 >= 2)") { @interpreter.parse_and_process(example.description).should == false }
    it("(2 >= 2)") { @interpreter.parse_and_process(example.description).should == true }
    it("(3 >= 2)") { @interpreter.parse_and_process(example.description).should == true }
  end

  describe "Binary expression" do
    it "(1 + 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end

  describe "Variable definition" do
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


  describe "for" do
    it "
      (let result 0)
      (for (let i 0)(i < 5)(let i (i + 1))
        (let result (result + i))
      )
      result
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 10
    end
  end

  describe "Array" do
    it "([1] .size)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "
      (let sum 0)
      ([1 2] .each
        (fnx item
          (let sum (sum + item))
        )
      )
      sum
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end
end
