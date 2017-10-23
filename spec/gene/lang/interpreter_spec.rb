require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Interpreter do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  describe "special built-in variables and functions" do
    it "# $application: the application object which is like the start of the universe
      (($invoke ($invoke $application 'class') 'name') == 'Gene::Lang::Application')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# $context: the current context
      (($invoke ($invoke $context 'class') 'name') == 'Gene::Lang::Context')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# $global: the global namespace object
      (($invoke ($invoke $global 'class') 'name') == 'Gene::Lang::Namespace')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# $scope: the current scope object which may or may not inherit from ancestor scopes
      (fn f _
        $scope
      )
      (($invoke ($invoke (f) 'class') 'name') == 'Gene::Lang::Scope')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# $function: the current function/method that is being called
      (fn f []
        $function
      )
      (($invoke ($invoke (f) 'class') 'name') == 'Gene::Lang::Function')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# $arguments: arguments passed to current function
      (fn f []
        $arguments
      )
      (((f 1 2) .data) == [1 2])
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# $invoke: a function that allows invocation of native methods on native objects (this should not be needed if whole interpreter is implemented in Gene Lang)
      (($invoke 'a' 'length') == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "class" do
    it "(class A)" do
      result = @application.parse_and_process(example.description)
      result.class.should == Gene::Lang::Class
      result.name.should  == 'A'
    end

    it "(class A)(new A)" do
      result = @application.parse_and_process(example.description)
      result.class.class.should == Gene::Lang::Class
      result.class.name.should  == 'A'
    end

    it "(class A (method doSomething))" do
      result = @application.parse_and_process(example.description)
      result.class.should == Gene::Lang::Class
      result.name.should  == 'A'
      result.methods.size.should == 1
    end

    it "# self: the self object in a method
      (class A
        (method f _ self)
      )
      (def a (new A))
      (((a .f) .class) == A)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# @a: access property `a` directly
      (class A
        (init a
          (@a = a)
        )
        (method test _
          @a
        )
      )
      (((new A 1) .test) == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# (@ a): access dynamic property
      (class A
        (init [name value]
          ((@ name) = value)
        )
        (method test name
          ((@ name))
        )
      )
      (((new A 'a' 100) .test 'a') == 100)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Typical usecase
      # Define class A
      (class A
        # Constructor
        (init a
          (@a = a)
        )

        # Define method incr-a
        (method incr-a _
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
      ((a .test 2) == 4)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "properties" do
    it "# with custom getter/setter
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
      ((a .x) == 'value')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# (prop x) will create default getter/setter methods
      (class A (prop x))
      (def a (new A))
      (a .x= 'value')
      ((a .x) == 'value')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "module" do
    it "# creating module, including module and inheritance etc should work
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
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "cast: will create a new object of the new class and shallow-copy all properties" do
    it "# `class` should return the new class
      (class A)
      (class B)
      (def a (new A))
      (((cast a B) .class) == B)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# invoking method on the new class should work
      (class A)
      (class B
        (method test _ 'test in B')
      )
      (def a (new A))
      (((cast a B) .test) == 'test in B')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Modification on casted object will not be lost
      (class A
        (method name _ @name)
      )
      (class B
        (method test _
          (@name = 'b')
        )
      )
      (def a (new A))
      ((cast a B) .test)
      ((a .name) == 'b')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "inheritance" do
    it "# If a method is not defined in my class, search in parent classes
      (class A
        (method testA _ 'testA')
      )
      (class B
        (extend A)
      )
      (def b (new B))
      ((b .testA) == 'testA')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Search method up to the top of class hierarchy
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
      ((c .test) == 'test in A')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# `super` will invoke same method in parent class
      (class A
        (method test [a b]
          (a + b)
        )
      )
      (class B
        (extend A)
        (method test [a b]
          (super a b)
        )
      )
      (def b (new B))
      ((b .test 1 2) == 3)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# `init` should be inherited
      (class A
        (init name
          (@name = name)
        )
        (method name _
          @name
        )
      )
      (class B
        (extend A)
      )
      (((new B 'test') .name) == 'test')
    " do
      result = @application.parse_and_process(example.description)
      pending
      result.should be_true
    end
  end

  describe "fn" do
    it "(fn doSomething)" do
      result = @application.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
    end

    it "(fn doSomething [a] (a + 1))" do
      result = @application.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.args_matcher.all_matchers.size.should == 1
      arg1 = result.args_matcher.data_matchers[0]
      arg1.index.should == 0
      arg1.name.should == 'a'
    end

    it "# Function parameters are passed by reference: check []
      (fn doSomething array
        ($invoke array 'push' 'doSomething')
      )
      (def a [])
      (doSomething a)
      (a == ['doSomething'])
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Function parameters are passed by reference: check {}
      (fn doSomething hash
        ($invoke hash '[]=' 'key' 'value')
      )
      (def a {})
      (doSomething a)
      (($invoke a '[]' 'key') == 'value')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    describe "Variable length arguments" do
      it "# In function definition
        (fn doSomething args... args)
        ((doSomething 1 2) == [1 2])
      " do
        result = @application.parse_and_process(example.description)
        result.should be_true
      end

      it "# In function invocation
        (fn doSomething [a b]
          (a + b)
        )
        (def array [1 2])
        ((doSomething array...) == 3)
      " do
        result = @application.parse_and_process(example.description)
        result.should be_true
      end

      it "# In both function definition and function invocation
        (fn doSomething args...
          args
        )
        (def array [1 2])
        ((doSomething array...) == [1 2])
      " do
        result = @application.parse_and_process(example.description)
        result.should be_true
      end
    end

    it "# Define and invoke function without arguments
      (fn doSomething _ 1)
      ((doSomething) == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# return nothing
      (fn doSomething _
        return
        2
      )
      ((doSomething) == undefined)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "
      # return something
      (fn doSomething _
        (return 1)
        2
      )
      ((doSomething) == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Invoke function immediately, note the double '(' and ')'
      (
        ((fn doSomething _ 1)) == 1
      )
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "(fn doSomething a 1)" do
      result = @application.parse_and_process(example.description)
      result.class.should == Gene::Lang::Function
      result.name.should  == 'doSomething'
      result.args_matcher.all_matchers.size.should == 1
      arg1 = result.args_matcher.data_matchers[0]
      arg1.index.should == 0
      arg1.name.should == 'a'
      result.statements.first.should == 1
    end

    it "# Define and invoke function with one argument
      (fn doSomething a a)
      ((doSomething 1) == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Define and invoke function with multiple arguments
      (fn doSomething [a b]
        (a + b)
      )
      ((doSomething 1 2) == 3)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# `call` invokes a function with a self, therefore makes the function behave like a method
      (fn f arg
        (.test arg)
      )
      (class A
        (method test arg arg)
      )
      (def a (new A))
      ((call f a 'value') == 'value') # self: a, arguments: 'value'
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# By default, function will inherit the scope where it is defined (like in JavaScript)
      (def a 1)
      (fn f b (a + b)) # `a` is inherited, `b` is an argument
      ((f 2) == 3)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "Method vs function" do
    it "# Method   WILL NOT   inherit the scope where it is defined in
      (class A
        (def x 1)
        (method doSomething _ x)
      )
      (def a (new A))
      (a .doSomething) # should throw error
    " do
      lambda {
        result = @application.parse_and_process(example.description)
      }.should raise_error
    end

    it "# Function   WILL   inherit the scope where it is defined in
      (def x 1)
      (fn doSomething _ x)
      ((doSomething) == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "fnx - anonymous function" do
    it "# Define and invoke an anonymous function
      (
        ((fnx _ 1)) == 1
      )
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Can be assigned to a variable and invoked later
      (def f (fnx _ 1))
      ((f) == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "fnxx - anonymous dummy function" do
    it "# Can be assigned to a variable and invoked later
      (def f (fnxx 1))
      ((f) == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "Variable" do
    it "# Must be defined first
      a # should throw error
    " do
      lambda {
        @application.parse_and_process(example.description)
      }.should raise_error
    end
  end

  describe "Assignment" do
    it "# `=` should work
      (def a)
      (a = 1)
      (a == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "Comparison" do
    it("((1 == 1) == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((1 == 2) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((1 != 1) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((1 != 2) == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((1 <  2) == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((2 <  2) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((3 <  2) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((1 <= 2) == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((2 <= 2) == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((3 <= 2) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((1 >  2) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((2 >  2) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((3 >  2) == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((1 >= 2) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((2 >= 2) == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((3 >= 2) == true)")  { @application.parse_and_process(example.description).should be_true }
  end

  describe "Boolean operations" do
    it("((true  && true)  == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((true  && false) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((false && false) == false)") { @application.parse_and_process(example.description).should be_true }
    it("((true  || true)  == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((true  || false) == true)")  { @application.parse_and_process(example.description).should be_true }
    it("((false || false) == false)") { @application.parse_and_process(example.description).should be_true }
  end

  describe "Binary expression" do
    it "((1 + 2) == 3)" do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "Variable definition" do
    it "(def a 'value')" do
      result = @application.parse_and_process(example.description)
      result.class.should == Gene::Lang::Variable
      result.name.should  == 'a'
      result.value.should == 'value'
    end

    it "# Define a variable and assign expression result as value
      (def a (1 + 2))
    " do
      result = @application.parse_and_process(example.description)
      result.class.should == Gene::Lang::Variable
      result.name.should  == 'a'
      result.value.should == 3
    end

    it "# Define and use variable
      (def a 1)
      ((a + 2) == 3)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Use multiple variables in one expression
      (def a 1)
      (def b 2)
      ((a + b) == 3)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "do" do
    it "# returns result of last expression
      (
        (do (def i 1)(i + 2)) == 3
      )
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "if" do
    it "# condition evaluates to true
      ((if true 1 2) == 1)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# condition evaluates to true
      ((if true [1 2] 2) == [1 2])
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# condition evaluates to true
      (
        (if true
          (do (def a 1)(a + 2))
          2
        ) == 3
      )
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# condition evaluates to false
      ((if false 1 2) == 2)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# condition evaluates to false
      ((if false 1 [1 2]) == [1 2])
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "if-not" do
    it "((if-not true 1 2) == 2)" do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "((if-not false 1 2) == 1)" do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "for
    # For statement has structure of (for init cond update statements...)
    # It can be used to create other type of loops, iterators etc
  " do
    it "# Basic usecase
      (def result 0)
      (for (def i 0)(i < 5)(i += 1)
        (result += i)
      )
      (result == 10)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# break from the for-loop
      (def result 0)
      (for (def i 0)(i < 100)(i += 1)
        (if (i >= 5) break)
        (result += i)
      )
      (result == 10)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# return from for-loop ?!
      (def result 0)
      (for (def i 0)(i < 100)(i += 1)
        (if (i >= 5) return)
        (result += i)
      )
      (result == 10)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "loop - creates simplist loop" do
    it "# Basic usecase
      (def i 0)
      (loop
        (i += 1)
        (if (i >= 5) break)
      )
      (i == 5)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# return value passed to `break`
      (def i 0)
      (
        (loop
          (i += 1)
          (if (i >= 5) (break 100))
        ) == 100
      )
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Loop as a regular function
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
      (
        (loop-test
          (i += 1)
          (if (i >= 5) (break 100))
        ) == 100
      )
    " do
      pending "TODO: fix infinite loop, might be related to variable scope"
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "noop - no operation, do nothing and return undefined" do
    it "(noop == undefined)" do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "_ is a placeholder, is equivalent to undefined" do
    it "# Putting _ at the place of arguments will not create an argument named `_`
      (fn f _ _)
      ((f 1) == undefined)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "((if true _ 1) == undefined)" do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# _ can be used in for-loop as placeholder
      (def sum 0)
      (def i 0)
      (for _ _ _
        (if (i > 4) break)
        (sum += i)
        (i += 1)
      )
      (sum == 10)
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "Namespace / module system" do
    it "# Namespace and members can be referenced from same scope
      (ns a
        (class C)
      )
      ((a/C .name) == 'C')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# Namespace and members can be referenced from nested scope
      (ns a
        (class C)
      )
      (class B
        (method test _
          (a/C .name)
        )
      )
      (((new B) .test) == 'C')
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end
  end

  describe "Decorators" do
    it "# should work on top level
      (def members [])
      (fn add_to_members f
        ($invoke members 'push' (f .name))
      )
      +add_to_members
      (fn test)
      (members == ['test'])
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# can be chained
      (def members [])
      (fn add_to_members f
        ($invoke members 'push' (f .name))
        f
      )
      +add_to_members
      +add_to_members
      (fn test)
      (members == ['test' 'test'])
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# should work inside ()
      (ns a
        (def members [])
        (fn add_to_members f
          ($invoke members 'push' (f .name))
        )
        +add_to_members
        (fn test)
      )
      (a/members == ['test'])
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# should work inside []
      (fn increment x
        (x + 1)
      )
      (def a [+increment 1])
      (a == [2])
    " do
      result = @application.parse_and_process(example.description)
      result.should be_true
    end

    it "# decorator can be invoked with arguments
      (def members [])
      (fn add_to_members [array f]
        ($invoke array 'push' (f .name))
      )
      (+add_to_members members)
      (fn test)
      (assert (members == ['test']))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "Assert" do
    it "(assert true)" do
      @application.parse_and_process(example.description)
    end

    it "(assert false)" do
      lambda {
        @application.parse_and_process(example.description)
      }.should raise_error('Assertion failure: false')
    end

    it "(assert false 'test message')" do
      lambda {
        @application.parse_and_process(example.description)
      }.should raise_error('Assertion failure: test message: false')
    end
  end

  describe "Arguments" do
    it "# should work
      (fn f [a b]
        (a += 1)
        (b *= 10)
        $arguments
      )
      (assert (((f 1 2).data) == [2 20]))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "AOP" do
    describe "before" do
      it "# should work
        (class A
          (init _
            (@values = [])
          )
          (before test _
            ($invoke @values 'push' 'before')
          )
          (method test _
            ($invoke @values 'push' 'test')
          )
        )
        (assert (((new A) .test) == ['before' 'test']))
      " do
        @application.parse_and_process(example.description)
      end
    end

    describe "after" do
      it "# should work
        (class A
          (init _
            (@values = [])
          )
          (after test _
            ($invoke @values 'push' 'after')
          )
          (method test _
            ($invoke @values 'push' 'test')
          )
        )
        (assert (((new A) .test) == ['test' 'after']))
      " do
        @application.parse_and_process(example.description)
      end
    end

    describe "when" do
      it "# should work
        (class A
          (init _
            (@values = [])
          )
          (when test _
            ($invoke @values 'push' 'when before')
            (continue)
            ($invoke @values 'push' 'when after')
          )
          (method test _
            ($invoke @values 'push' 'test')
          )
        )
        #(assert (((new A) .test) == ['when before' 'test' 'when after']))
        ((new A) .test)
      " do
        result = @application.parse_and_process(example.description)
        result.should == ['when before', 'test', 'when after']
      end

      it "# multiple `when` should work
        (class A
          (init _
            (@values = [])
          )
          (when test _
            ($invoke @values 'push' 'when before')
            (continue)
            ($invoke @values 'push' 'when after')
          )
          (when test _
            ($invoke @values 'push' 'when before2')
            (continue)
            ($invoke @values 'push' 'when after2')
          )
          (method test _
            ($invoke @values 'push' 'test')
          )
        )
        #(assert (((new A) .test) == ['when before' 'test' 'when after']))
        ((new A) .test)
      " do
        result = @application.parse_and_process(example.description)
        result.should == ['when before', 'when before2', 'test', 'when after2', 'when after']
      end
    end
  end
end
