require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Interpreter do
  before do
    @application = Gene::Lang::Application.new
    @interpreter = Gene::Lang::Interpreter.new @application.root_context
  end

  describe "special built-in variables and functions" do
    it "
      $application  # The application object which is like the start of the universe
    " do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Application
    end

    it "
      $context      # The current context
    " do
      result = @interpreter.parse_and_process(example.description)
      result.scope.should_not be_nil
    end

    it "
      $global-scope # The global scope object
    " do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Scope
    end

    it "
      $scope        # The current scope object which may or may not inherit from ancestor scopes
    " do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Scope
    end

    it "
      (fn f []
        $function   # The current function/method that is being called
      )
      (f) # returns the function itself
    " do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should == 'f'
    end

    it "
      (fn f []
        $arguments  # array of arguments passed to current function
      )
      (f 1 2) # returns [1, 2]
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == [1, 2]
    end

    it "
      ($invoke      # A function that allows invocation of native methods on native objects (this should not be needed if whole interpreter is implemented in Gene Lang)
        $scope 'class') # returns 'Gene::Lang::Scope'
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::Lang::Scope
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
      result.methods.size.should == 1
    end

    it "
      # self is the self object in a method
      (class A
        (method f [] self)
      )
      (def a (new A))
      (a .f)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.class.name.should == 'A'
    end

    it "(class A (init a (@a = a))) (new A 1)" do
      result = @interpreter.parse_and_process(example.description)
      result['a'].should == 1
    end

    it "(class A (init name ((@ name) = 1))) (new A 'a')" do
      result = @interpreter.parse_and_process(example.description)
      result['a'].should == 1
    end

    it "
      # Define class A
      (class A
        # Constructor
        (init a
          (@a = a)
        )
        # Define method incr-a
        (method incr-a []
          (@a += 1)
        )
        # Define method test
        (method test num
          # Here is how you call method from same class
          (.incr-a)
          (@a + num)
        )
      )

      # Instantiate A
      (def a (new A 1))
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
          ^set [value (@x = value)]
        )
      )
      (def a (new A))
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
      (def a (new A))
      (a .x= 'value')
      (a .x)
    " do
      result = Gene::Parser.parse(example.description)
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end
  end

  describe "module" do
    it "
      (class A
        (method test _
          (@value = ($invoke @value 'push' 'A.test'))
          @value
        )
      )
      (module M)
      (module N
        (include M)
      )
      (module O)
      (class B
        (extend A)
        (include N)
        (include O)
        (init _ (@value = []))
        (method test _
          (super)
          (@value = ($invoke @value 'push' 'B.test'))
          @value
        )
      )
      (def b (new B))
      ((b .test) == ['A.test' 'B.test'])
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == true
    end
  end

  describe "cast" do
    it "
      (class A)
      (class B)
      (def a (new A))
      # cast will create a new object of B, shallow-copy all properties except #class
      (cast a B)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.class.class.should == Gene::Lang::Class
      result.class.name.should  == 'B'
    end

    it "
      (class A)
      (class B (method test [] 'test in B'))
      (def a (new A))
      ((cast a B) .test)  # returns 'test in B'
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should  == 'test in B'
    end

    it "
      # Modification on casted object will not be lost
      (class A)
      (class B (method test [] (@name = 'b')))
      (def a (new A))
      ((cast a B) .test)
      a  # @name should be 'b'
    " do
      result = @interpreter.parse_and_process(example.description)
      result['name'].should  == 'b'
    end
  end

  describe "inheritance" do
    it "
      # If a method is not defined in my class, search in parent classes
      (class A
        (method testA _ 'testA')
      )
      (class B
        (extend A)
      )
      (def b (new B))
      (b .testA)  # returns 'testA'
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should  == 'testA'
    end

    it "
      # If a method is not defined in my class, search in parent classes
      (class A
        (method test _ 'test in A')
      )
      (class B)
      (class C
        (extend A)
        (extend B)
      )
      (def c (new C))
      (c .test)  # returns 'test in A'
    " do
      pending "TODO: change to module/include"
      result = @interpreter.parse_and_process(example.description)
      result.should  == 'test in A'
    end

    it "
      # Search method up to the top of class hierarchy
      (class A
        (method test _ 'test in A')
      )
      (class B
        (extend A)
      )
      (class C
        (extend B)
      )
      (def c (new C))
      (c .test)  # returns 'test in A'
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should  == 'test in A'
    end

    it "
      # Super class defined later takes precedence
      (class A
        (method test _ 'test in A')
      )
      (class B
        (method test _ 'test in B')
      )
      (class C
        (extend A)
        (extend B)
      )
      (def c (new C))
      (c .test)  # returns 'test in B'
    " do
      pending "TODO: change to module/include"
      result = @interpreter.parse_and_process(example.description)
      result = @interpreter.parse_and_process(example.description)
      result.should  == 'test in B'
    end

    it "
      # super will invoke same method in parent class
      (class A
        (method test [a b] (a + b))
      )
      (class B
        (extend A)
        (method test [a b] (super a b))
      )
      (def b (new B))
      (b .test 1 2)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should  == 3
    end

    describe "init" do
      it "
        # init is not inherited, must be called explicitly
        (class A
          (init _ (@a = 1))
        )
        (class B
          (extend A)
        )
        (new B)
      " do
        result = @interpreter.parse_and_process(example.description)
        result['a'].should be_nil
      end

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

    describe "Variable length arguments" do
      it "
        (fn doSomething args... args)
        (doSomething 1 2)
      " do
        result = @interpreter.parse_and_process(example.description)
        result.should == [1, 2]
      end

      it "
        (fn doSomething [a b]
          (a + b)
        )
        (def array [1 2])
        (doSomething array...)
      " do
        result = @interpreter.parse_and_process(example.description)
        result.should == 3
      end

      it "
        (fn doSomething args...
          args
        )
        (def array [1 2])
        (doSomething array...)
      " do
        result = @interpreter.parse_and_process(example.description)
        result.should == [1, 2]
      end
    end

    it "(fn doSomething [] 1)(doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "
      # return from function
      (fn doSomething []
        return
        2
      )
      (doSomething)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "
      # return value from function
      (fn doSomething []
        (return 1)
        2
      )
      (doSomething)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
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
      (def a (new A))
      # call will invoke a function with a self, this makes function behave like method
      (call f a)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "
      (def a 1)
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
        (def x 1)
        (method doSomething [] x)
      )
      (def a (new A))
      (a .doSomething)
    " do
      lambda {
        result = @interpreter.parse_and_process(example.description)
      }.should raise_error
    end

    it "
      # Function   WILL   inherit the scope where it is defined in
      (def x 1)
      (fn doSomething [] x)
      (doSomething)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end

  describe "fnx - anonymous function" do
    it "
      (def f (fnx [] 1))
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
      (def f (fnxx 1))
      (f)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end

  describe "Variable" do
    it "# Must be difined first
      a # should throw exception
    " do
      lambda {
        @interpreter.parse_and_process(example.description)
      }.should raise_error
    end
  end

  describe "Assignment" do
    it "# = should work
      (def a)
      (a = 1)
      (a == 1)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "Comparison" do
    it("(1 == 1)") { @interpreter.parse_and_process(example.description).should == true }
    it("(1 == 2)") { @interpreter.parse_and_process(example.description).should == false }
    it("(1 != 1)") { @interpreter.parse_and_process(example.description).should == false }
    it("(1 != 2)") { @interpreter.parse_and_process(example.description).should == true }
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

  describe "Boolean operations" do
    it("(true && true)")   { @interpreter.parse_and_process(example.description).should == true }
    it("(true && false)")  { @interpreter.parse_and_process(example.description).should == false }
    it("(true || true)")   { @interpreter.parse_and_process(example.description).should == true }
    it("(true || false)")  { @interpreter.parse_and_process(example.description).should == true }
    it("(false || false)") { @interpreter.parse_and_process(example.description).should == false }
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

    it "(def a 'value')" do
      result = @interpreter.parse_and_process(example.description)
      @interpreter.context.get('a').should == 'value'
      pending "should we return undefined or value instead?"
      result.class.should == Gene::Lang::Variable
      result.name.should  == 'a'
      result.value.should == 'value'
    end

    it "(def a (1 + 2))" do
      result = @interpreter.parse_and_process(example.description)
      @interpreter.context.get('a').should == 3
      pending "should we return undefined or value instead?"
      result.class.should == Gene::Lang::Variable
      result.name.should  == 'a'
      result.value.should == 3
    end

    it "(def a 1) (a + 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    it "(def a 1) (def b 2) (a + b)" do
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
        pending "Deprecated"
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
        pending "Deprecated"
        result = @interpreter.parse_and_process(example.description)
        result.should == 1
      end
    end
  end

  describe "do" do
    it "(do (def i 1)(i + 2))" do
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

    it "(if true (do (def a 1)(a + 2)) 2)" do
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

  describe "if-not" do
    it "(if-not true 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end

    it "(if-not false 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end

  describe "for
    # For statement has structure of (for init cond update statements...)
    # It can be used to create other type of loops, iterators etc
  " do
    it "
      (def result 0)
      (for (def i 0)(i < 5)(i += 1)
        (def result (result + i))
      )
      (result == 10)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should be_true
    end

    it "
      (def result 0)
      (for (def i 0)(i < 100)(i += 1)
        (if (i >= 5) break)
        (def result (result + i))
      )
      (result == 10)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should be_true
    end

    it "
      (def result 0)
      (for (def i 0)(i < 100)(i += 1)
        (if (i >= 5) return)
        (def result (result + i))
      )
      (result == 10)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "loop - creates simplist loop" do
    it "
      (def i 0)
      (loop
        (i += 1)
        (if (i >= 5) break)
      )
      (i == 5)
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should be_true
    end

    it "
      (def i 0)
      (loop
        (i += 1)
        (if (i >= 5) (break 100))
      )
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 100
    end

    it "
      # Loop as a regular function
      (fn loop-test args...
        ^!inherit-scope ^!eval-arguments
        # Do not inherit scope from where it's defined in: equivalent to ^!inherit-scope
        # args are not evaluated before passed in: equivalent to ^!eval-arguments
        #
        # After evaluation, ReturnValue are returned as is, BreakValue are unwrapped and returned
        (loop
          (def result ($invoke $caller-context 'process_statements' args))
          (if (($invoke ($invoke result 'class') 'name') == 'BreakValue')
            (return ($invoke result 'value'))
          )
        )
      )
      (def i 0)
      (loop-test
        (i += 1)
        (if (i >= 5) (break 100))
      )
    " do
      pending "TODO: fix infinite loop, might be related to variable scope"
      result = @interpreter.parse_and_process(example.description)
      result.should == 100
    end
  end

  describe "noop - no operation, do nothing and return undefined" do
    it "noop" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
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
      (def sum 0)
      (def i 0)
      (for _ _ _
        (if (i > 4) break)
        (sum += i)
        (i += 1)
      )
      sum
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == 10
    end
  end
end
