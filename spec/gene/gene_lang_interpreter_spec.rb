require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Lang::Interpreter do
  before do
    @interpreter = Gene::Lang::Interpreter.new
  end

  describe "special built-in variables and functions" do
    it "$context: The interpreter's context" do
      result = @interpreter.parse_and_process("
        (let a 1)
        $context
      ")
      result.scope.get_variable('a').should == 1
    end

    it "$global: The global scope object" do
      result = @interpreter.parse_and_process("
        ($invoke $global 'get_variable' 'Array')
      ")
      result.name.should == "Array"
    end

    it "$scope: The current scope object which inherits from ancestor scopes" do
      result = @interpreter.parse_and_process("
        (let a 1)
        $scope
      ")
      result.get_variable('a').should == 1
    end

    it "$arguments: array of arguments passed to current function" do
      result = @interpreter.parse_and_process("
        (fn f [] $arguments)
        (f 1 2)
      ")
      result.should == [1, 2]
    end

    it "$invoke: A function that allows invocation of native methods on native objects (this should not be needed if whole interpreter is implemented in Gene Lang)" do
      result = @interpreter.parse_and_process("
        (let a 1)
        # Invoke get_variable method on current scope (the scope is a native object)
        ($invoke $scope 'get_variable' 'a')
      ")
      result.should == 1
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

    it "
      # self is the self object in a method
      (class A
        (method f [] self)
      )
      (let a (new A))
      (a .f)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.class.name.should == 'A'
    end

    it "(class A (init a (let @a a))) (new A 1)" do
      result = @interpreter.parse_and_process(example.description)
      result['a'].should == 1
    end

    it "
      # Define class A
      (class A
        # Constructor
        (init a
          (let @a a)
        )
        # Define method incr-a
        (method incr-a []
          (let @a (@a + 1))
        )
        # Define method test
        (method test num
          # Here is how you call method from same class
          (.incr-a)
          (@a + num)
        )
      )

      # Instantiate A
      (let a (new A 1))
      # Call method on an instance
      (a .test 2)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 4
    end
  end

  describe "properties" do
    it "
      (class A
        # Define a property named x
        (prop x
          # TODO: rethink how getter/setter logic is defined
          ^get [@x]
          ^set [value (let @x value)]
        )
      )
      (let a (new A))
      # Property x can be accessed like methods
      (a .x= 'value')
      (a .x)
    " do
      result = Gene::Parser.parse(example.description)
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "
      # (prop x) will create default getter/setter methods
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
      # cast will create a new object of B, replicate all attributes except #class
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

    it "(fn doSomething [a] (a + 1))" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.arguments.size.should == 1
      result.arguments[0].index.should == 0
      result.arguments[0].name.should == 'a'
    end

    it "(fn doSomething [] 1)(doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(fn doSomething [] 1)(doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(fn doSomething [] (return 1) 2)(doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "
      (fn doSomething []
        return
        2
      )
      (doSomething)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "((fn doSomething [] 1)) # Note the double '(' and ')'" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(fn doSomething a 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.arguments.size.should == 1
      result.arguments[0].index.should == 0
      result.arguments[0].name.should == 'a'
      result.statements.first.should == 1
    end

    it "(fn doSomething a a)(doSomething 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(fn doSomething [a b] (a + b))(doSomething 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    it "
      (fn f [] (.x))
      (class A (method x [] 'value'))
      (let a (new A))
      # call will invoke a function with a self, this makes function behave like method
      (call f a)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "
      (let a 1)
      # By default, function will inherit the scope where it is defined (like in JavaScript)
      (fn f b (a + b))
      (f 2)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end

  describe "Method vs function" do
    it "1.
      # Method   WILL NOT   inherit the scope where it is defined in
      (class A
        (let x 1)
        (method doSomething [] x)
      )
      (let a (new A))
      (a .doSomething)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "
      # Function   WILL   inherit the scope where it is defined in
      (let x 1)
      (fn doSomething [] x)
      (doSomething)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end

  describe "fnx - anonymous function" do
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

  describe "fnxx - anonymous dummy function" do
    it "
      (let f (fnxx 1))
      (f)
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
    it "(def a 'value')" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Variable
      result.name.should  == 'a'
      result.value.should == 'value'
    end

    it "(def a (1 + 2))" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Variable
      result.name.should  == 'a'
      result.value.should == 3
    end

    it "(def a 1) (a + 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
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

    it "(let a 1) (a + 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    it "(def a 1) (let b 2) (a + b)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    describe "def vs let" do
      it "
        # def will not overwrite variable in ancestor scope,
        # but will create a new variable in current scope
        (def x 0)
        (fn f [] (def x 1))
        (f)
        x
      " do
        result = @interpreter.parse_and_process(example.description)
        result.should == 0
      end

      it "
        # let will overwrite variable in ancestor scope,
        # or create a new variable if it doesn't exist in current or ancestor scopes
        (let x 0)
        (fn f [] (let x 1))
        (f)
        x
      " do
        result = @interpreter.parse_and_process(example.description)
        result.should == 1
      end
    end
  end

  describe "do" do
    it "(do (let i 1)(i + 2))" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end
  end

  describe "if" do
    it "(if true 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(if true [1 2] 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == [1, 2]
    end

    it "(if true (do (let a 1)(a + 2)) 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    it "(if false 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end

    it "(if false 1 [1 2])" do
      result = @interpreter.parse_and_process(example.description)
      result.should == [1, 2]
    end
  end

  describe "for
    # For statement has structure of (for init cond update statements...)
    # It can be used to create other type of loops, iterators etc
  " do
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

  describe "loop - creates simplist loop" do
    it "
      (let i 0)
      (loop
        (let i (i + 1))
        (if (i >= 5) break)
      )
      i
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 5
    end

    it "
      (let i 0)
      (loop
        (let i (i + 1))
        (if (i >= 5) (break 100))
      )
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 100
    end
  end

  describe "_ is a placeholder, is equivalent to undefined" do
    it "
      # Putting _ at the place of arguments will not create an argument named _
      (fn f _ _)
      (f 1)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "(if true _ 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "
      (let sum 0)
      (let i 0)
      (for _ (i <= 4) _
        (let sum (sum + i))
        (let i (i + 1))
      )
      sum
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 10
    end
  end

  describe "Array
    # Array is created as a native array in the hosted language
    # When a method invocation occurs to an array, a proxy object is created on the fly
    # The proxy object is an instance of Gene::Lang::Array
    # This approach is applied on all literals and hash objects as well
  " do
    it "([1] .size)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "
      (let sum 0)
      # each is a method defined in Gene::Lang::Array
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
