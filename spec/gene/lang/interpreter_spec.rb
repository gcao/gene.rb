require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Interpreter do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  describe "special built-in variables and functions" do
    it "# $application: the application object which is like the start of the universe
      (assert (($invoke ($invoke $application 'class') 'name') == 'Gene::Lang::Application'))
    " do
      @application.parse_and_process(example.description)
    end

    it "# $context: the current context
      (assert (($invoke ($invoke $context 'class') 'name') == 'Gene::Lang::Context'))
    " do
      @application.parse_and_process(example.description)
    end

    it "# $global: the global namespace object
      (assert (($invoke ($invoke $global 'class') 'name') == 'Gene::Lang::Namespace'))
    " do
      @application.parse_and_process(example.description)
    end

    it "# $scope: the current scope object which may or may not inherit from ancestor scopes
      (fn f _
        $scope
      )
      (assert (($invoke ($invoke (f) 'class') 'name') == 'Gene::Lang::Scope'))
    " do
      @application.parse_and_process(example.description)
    end

    it "# $function: the current function/method that is being called
      (fn f []
        $function
      )
      (assert (($invoke ($invoke (f) 'class') 'name') == 'Gene::Lang::Function'))
    " do
      @application.parse_and_process(example.description)
    end

    it "# $arguments: arguments passed to current function
      (fn f []
        $arguments
      )
      (assert (((f 1 2) .data) == [1 2]))
    " do
      @application.parse_and_process(example.description)
    end

    it "# $invoke: a function that allows invocation of native methods on native objects (this should not be needed if whole interpreter is implemented in Gene Lang)
      (assert (($invoke 'a' 'length') == 1))
    " do
      @application.parse_and_process(example.description)
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
      (assert (((a .f) .class) == A))
    " do
      @application.parse_and_process(example.description)
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
      (assert (((new A 1) .test) == 1))
    " do
      @application.parse_and_process(example.description)
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
      (assert (((new A 'a' 100) .test 'a') == 100))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((a .test 2) == 4))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((a .x) == 'value'))
    " do
      @application.parse_and_process(example.description)
    end

    it "# (prop x) will create default getter/setter methods
      (class A (prop x))
      (def a (new A))
      (a .x= 'value')
      (assert ((a .x) == 'value'))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((b .test) == ['A.test' 'B.test']))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "cast: will create a new object of the new class and shallow-copy all properties" do
    it "# `class` should return the new class
      (class A)
      (class B)
      (def a (new A))
      (assert (((cast a B) .class) == B))
    " do
      @application.parse_and_process(example.description)
    end

    it "# invoking method on the new class should work
      (class A)
      (class B
        (method test _ 'test in B')
      )
      (def a (new A))
      (assert (((cast a B) .test) == 'test in B'))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((a .name) == 'b'))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((b .testA) == 'testA'))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((c .test) == 'test in A'))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((b .test 1 2) == 3))
    " do
      @application.parse_and_process(example.description)
    end

    it "# `init` should be inherited
      (class A
        (prop name)
        (init name
          (@name = name)
        )
      )
      (class B
        (extend A)
      )
      (def b (new B 'test'))
      (assert ((b .name) == 'test'))
    " do
      @application.parse_and_process(example.description)
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
      (assert (a == ['doSomething']))
    " do
      @application.parse_and_process(example.description)
    end

    it "# Function parameters are passed by reference: check {}
      (fn doSomething hash
        ($invoke hash '[]=' 'key' 'value')
      )
      (def a {})
      (doSomething a)
      (assert (($invoke a '[]' 'key') == 'value'))
    " do
      @application.parse_and_process(example.description)
    end

    describe "Variable length arguments" do
      it "# In function definition
        (fn doSomething args... args)
        (assert ((doSomething 1 2) == [1 2]))
      " do
        @application.parse_and_process(example.description)
      end

      it "# In function invocation
        (fn doSomething [a b]
          (a + b)
        )
        (def array [1 2])
        (assert ((doSomething array...) == 3))
      " do
        @application.parse_and_process(example.description)
      end

      it "# In both function definition and function invocation
        (fn doSomething args...
          args
        )
        (def array [1 2])
        (assert ((doSomething array...) == [1 2]))
      " do
        @application.parse_and_process(example.description)
      end
    end

    it "# Define and invoke function without arguments
      (fn doSomething _ 1)
      (assert ((doSomething) == 1))
    " do
      @application.parse_and_process(example.description)
    end

    it "# return nothing
      (fn doSomething _
        return
        2
      )
      (assert ((doSomething) == undefined))
    " do
      @application.parse_and_process(example.description)
    end

    it "# return something
      (fn doSomething _
        (return 1)
        2
      )
      (assert ((doSomething) == 1))
    " do
      @application.parse_and_process(example.description)
    end

    it "# Invoke function immediately, note the double '(' and ')'
      (assert (((fn doSomething _ 1)) == 1))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((doSomething 1) == 1))
    " do
      @application.parse_and_process(example.description)
    end

    it "# Define and invoke function with multiple arguments
      (fn doSomething [a b]
        (a + b)
      )
      (assert ((doSomething 1 2) == 3))
    " do
      @application.parse_and_process(example.description)
    end

    it "# `call` invokes a function with a self, therefore makes the function behave like a method
      (fn f arg
        (.test arg)
      )
      (class A
        (method test arg arg)
      )
      (def a (new A))
      (assert ((call f a 'value') == 'value')) # self: a, arguments: 'value'
    " do
      @application.parse_and_process(example.description)
    end

    it "# By default, function will inherit the scope where it is defined (like in JavaScript)
      (def a 1)
      (fn f b (a + b)) # `a` is inherited, `b` is an argument
      (assert ((f 2) == 3))
    " do
      @application.parse_and_process(example.description)
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
      (assert ((doSomething) == 1))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "fnx - anonymous function" do
    it "# Define and invoke an anonymous function
      (assert (((fnx _ 1)) == 1))
    " do
      @application.parse_and_process(example.description)
    end

    it "# Can be assigned to a variable and invoked later
      (def f (fnx _ 1))
      (assert ((f) == 1))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "fnxx - anonymous dummy function" do
    it "# Can be assigned to a variable and invoked later
      (def f (fnxx 1))
      (assert ((f) == 1))
    " do
      @application.parse_and_process(example.description)
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
      (assert (a == 1))
    " do
      @application.parse_and_process(example.description)
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
    it "(assert ((1 + 2) == 3))" do
      @application.parse_and_process(example.description)
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
      (assert ((a + 2) == 3))
    " do
      @application.parse_and_process(example.description)
    end

    it "# Use multiple variables in one expression
      (def a 1)
      (def b 2)
      (assert ((a + b) == 3))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "do" do
    it "# returns result of last expression
      (assert
        ((do (def i 1)(i + 2)) == 3)
      )
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "if" do
    it "# condition evaluates to true
      (assert ((if true 1 2) == 1))
    " do
      @application.parse_and_process(example.description)
    end

    it "# condition evaluates to true
      (assert ((if true [1 2] 2) == [1 2]))
    " do
      @application.parse_and_process(example.description)
    end

    it "# condition evaluates to true
      (assert
        ((if true
          (do (def a 1)(a + 2))
          2
        ) == 3)
      )
    " do
      @application.parse_and_process(example.description)
    end

    it "# condition evaluates to false
      (assert ((if false 1 2) == 2))
    " do
      @application.parse_and_process(example.description)
    end

    it "# condition evaluates to false
      (assert ((if false 1 [1 2]) == [1 2]))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "if-not" do
    it "(assert ((if-not true 1 2) == 2))" do
      @application.parse_and_process(example.description)
    end

    it "(assert ((if-not false 1 2) == 1))" do
      @application.parse_and_process(example.description)
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
      (assert (result == 10))
    " do
      @application.parse_and_process(example.description)
    end

    it "# break from the for-loop
      (def result 0)
      (for (def i 0)(i < 100)(i += 1)
        (if (i >= 5) break)
        (result += i)
      )
      (assert (result == 10))
    " do
      @application.parse_and_process(example.description)
    end

    it "# return from for-loop ?!
      (def result 0)
      (for (def i 0)(i < 100)(i += 1)
        (if (i >= 5) return)
        (result += i)
      )
      (assert (result == 10))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "loop - creates simplist loop" do
    it "# Basic usecase
      (def i 0)
      (loop
        (i += 1)
        (if (i >= 5) break)
      )
      (assert (i == 5))
    " do
      @application.parse_and_process(example.description)
    end

    it "# return value passed to `break`
      (def i 0)
      (assert
        ((loop
          (i += 1)
          (if (i >= 5) (break 100))
        ) == 100)
      )
    " do
      @application.parse_and_process(example.description)
    end

    it "# Use `loop` to build `for` as a regular function
      (fn for-test [init cond update stmts...]
        ^!inherit-scope ^!eval-arguments
        # Do not inherit scope from where it's defined in: equivalent to ^!inherit-scope
        # Args are not evaluated before passed in: equivalent to ^!eval-arguments
        #
        # After evaluation, ReturnValue are returned as is, BreakValue are unwrapped and returned
        ($invoke $caller-context 'process_statements' init)
        (loop
          # check condition and break if false
          (def result ($invoke $caller-context 'process_statements' cond))
          (if (($invoke ($invoke result 'class') 'name') == 'Gene::Lang::BreakValue')
            (return ($invoke result 'value'))
          )
          (if-not result
            return
          )

          ($invoke $caller-context 'process_statements' stmts)
          ($invoke $caller-context 'process_statements' update)
        )
      )
      (def result 0)
      (for-test (def i 0) (i <= 4) (i += 1)
        (result += i)
      )
      (assert (result == 10))
    " do
      @application.parse_and_process(example.description)
    end

    it "# Use `for` to build `loop` as a regular function
      (fn loop-test args...
        ^!inherit-scope ^!eval-arguments
        # Do not inherit scope from where it's defined in: equivalent to ^!inherit-scope
        # Args are not evaluated before passed in: equivalent to ^!eval-arguments
        #
        # After evaluation, ReturnValue are returned as is, BreakValue are unwrapped and returned
        (for _ _ _
          (def result ($invoke $caller-context 'process_statements' args))
          (if (($invoke ($invoke result 'class') 'name') == 'Gene::Lang::BreakValue')
            (return ($invoke result 'value'))
          )
        )
      )
      (def i 0)
      (assert
        ((loop-test
          (i += 1)
          (if (i >= 5) (break 100))
        ) == 100)
      )
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "noop - no operation, do nothing and return undefined" do
    it "(assert (noop == undefined))" do
      @application.parse_and_process(example.description)
    end
  end

  describe "_ is a placeholder, is equivalent to undefined" do
    it "# Putting _ at the place of arguments will not create an argument named `_`
      (fn f _ _)
      (assert ((f 1) == undefined))
    " do
      @application.parse_and_process(example.description)
    end

    it "(assert ((if true _ 1) == undefined))" do
      @application.parse_and_process(example.description)
    end

    it "# _ can be used in for-loop as placeholder
      (def sum 0)
      (def i 0)
      (for _ _ _
        (if (i > 4) break)
        (sum += i)
        (i += 1)
      )
      (assert (sum == 10))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "Namespace / module system" do
    it "# Namespace and members can be referenced from same scope
      (ns a
        (class C)
      )
      (assert ((a/C .name) == 'C'))
    " do
      @application.parse_and_process(example.description)
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
      (assert (((new B) .test) == 'C'))
    " do
      @application.parse_and_process(example.description)
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
      (assert (members == ['test']))
    " do
      @application.parse_and_process(example.description)
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
      (assert (members == ['test' 'test']))
    " do
      @application.parse_and_process(example.description)
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
      (assert (a/members == ['test']))
    " do
      @application.parse_and_process(example.description)
    end

    it "# should work inside []
      (fn increment x
        (x + 1)
      )
      (def a [+increment 1])
      (assert (a == [2]))
    " do
      @application.parse_and_process(example.description)
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

  describe "with - create a new context with a given self" do
    it "# should work
      (def o (new Object))
      (with o
        (assert ((.class) == Object))
      )
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "Exception" do
    it "(throw 'some error')" do
      lambda {
        @application.parse_and_process(example.description)
      }.should raise_error('some error')
    end

    it "# catch (will inherit scope etc)
      (catch
        ^Exception (fnx e (result = 'Exception'))
        ^default   (fnx e (result = 'default'))
        (def result)
        (throw 'some error')
      )
      (assert (result == 'Exception'))
    " do
      @application.parse_and_process(example.description)
    end

    it "# catch default (won't catch runtime error)
      (catch
        ^default (fnx e (result = 'default'))
        (def result)
        (throw 'some error')
      )
      (assert (result == 'default'))
    " do
      pending
      @application.parse_and_process(example.description)
    end

    it "# catch default (won't catch runtime error)
      (catch
        ^default (fnx e (result = 'default'))
        (def result)
        (throw RuntimeError 'some error')
      )
    " do
      pending
      lambda {
        @application.parse_and_process(example.description)
      }.should raise_error('some error')
    end

    it "# ensure
      (catch
        ^default (fnx e (a = 'default'))
        ^ensure ()
        (def a)
        (throw RuntimeError 'some error')
      )
    " do
      pending
      lambda {
        @application.parse_and_process(example.description)
      }.should raise_error('some error')
    end

    it "# do...catch
      (def result)
      (do
        ^catch {
          ^Exception (fnx e (result = 'Exception'))
        }
        (throw 'some error')
      )
      (assert (result == 'Exception'))
    " do
      pending
      @application.parse_and_process(example.description)
    end

    it "# do...catch default
      (def result)
      (do
        ^catch (fnx e (result = (e .message)))
        (throw 'some error')
      )
      (assert (result == 'some error'))
    " do
      pending
      @application.parse_and_process(example.description)
    end

    it "# fn...catch: the callback should run in the context of function
      (fn
        ^catch {
          ^Exception (fnx e (result = 'Exception'))
        }
        (def result)
        (throw 'some error')
      )
      (assert (result == 'Exception'))
    " do
      pending
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

      it "# multiple `before`
        (class A
          (init _
            (@values = [])
          )
          (before test _
            ($invoke @values 'push' 'before')
          )
          (before test _
            ($invoke @values 'push' 'before2')
          )
          (method test _
            ($invoke @values 'push' 'test')
          )
        )
        (assert (((new A) .test) == ['before' 'before2' 'test']))
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

      it "# multiple `after`
        (class A
          (init _
            (@values = [])
          )
          (after test _
            ($invoke @values 'push' 'after')
          )
          (after test _
            ($invoke @values 'push' 'after2')
          )
          (method test _
            ($invoke @values 'push' 'test')
          )
        )
        (assert (((new A) .test) == ['test' 'after' 'after2']))
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
        (assert (((new A) .test) == ['when before' 'test' 'when after']))
      " do
        @application.parse_and_process(example.description)
      end

      it "# multiple `when`
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
        (assert (((new A) .test) == ['when before' 'when before2' 'test' 'when after2' 'when after']))
      " do
        @application.parse_and_process(example.description)
      end
    end

    it "# before + when + after
      (class A
        (init _
          (@values = [])
        )
        (before test _
          ($invoke @values 'push' 'before')
        )
        (when test _
          ($invoke @values 'push' 'when before')
          (continue)
          ($invoke @values 'push' 'when after')
        )
        (after test _
          ($invoke @values 'push' 'after')
        )
        (method test _
          ($invoke @values 'push' 'test')
        )
      )
      (assert (((new A) .test) == ['before' 'when before' 'test' 'when after' 'after']))
    " do
      @application.parse_and_process(example.description)
    end
  end

  describe "Aspect" do
    it "# should work
      (aspect A
        (before test _
          ($invoke @values 'push' 'before')
        )
        (when test _
          ($invoke @values 'push' 'when before')
          (continue)
          ($invoke @values 'push' 'when after')
        )
        (after test _
          ($invoke @values 'push' 'after')
        )
      )
      (class C
        (init _
          (@values = [])
        )
        (method test _
          ($invoke @values 'push' 'test')
        )
      )
      (A .apply C)
      (def c (new C))
      (assert ((c .test) == ['before' 'when before' 'test' 'when after' 'after']))
    " do
      @application.parse_and_process(example.description)
    end
  end
end
