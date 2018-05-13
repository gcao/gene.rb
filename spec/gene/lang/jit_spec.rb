require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "JIT" do
  before do
    @compiler = Compiler.new
  end

  describe "Atomic expressions" do
    it "
      1
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      'hello world'
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 'hello world'
    end

    it "
      true
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should be_true
    end

    it "
      false
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should be_false
    end

    it "
      null
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should be_nil
    end

    it "
      :a
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == Gene::Types::Symbol.new('a')
    end

    it "
      (:a 1)
    " do
      pending
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      result = app.run
      result.type.should == Gene::Types::Symbol.new('a')
      result.data.should == [1]
    end

    it "
      [1 2]
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == [1, 2]
    end

    it "
      (var a 1)
      [a 2]
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == [1, 2]
    end

    it "
      {^a 1 ^b 2}
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == {'a' => 1, 'b' => 2}
    end

    it "
      (var a 1)
      {^a a ^b 2}
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == {'a' => 1, 'b' => 2}
    end

    it "
      (1 + 2)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 3
    end

    it "
      (true || false)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == true
    end

    it "
      (true && false)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == false
    end

    it "
      (! true)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == false
    end

    it "
      (! false)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == true
    end

    it "
      ($invoke 'abc' '[]' 1)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 'b'
    end

    it "
      ('' 1 2 '3')
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == '123'
    end

    it "
      (var a 1)
      a
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # a... should work
      (var a [1 2])
      [a... 3]
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == [1, 2, 3]
    end

    it "
      # += should work
      (var a 1)
      (a += 2)
      a
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 3
    end

    it "
      # -= should work
      (var a 3)
      (a -= 2)
      a
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # if should work
      (if true 1 else 2)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # else should work
      (if false 1 else 2)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 2
    end

    it "
      # loop...break should work
      (loop (if true break))
      1
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # for should work
      (var sum 0)
      (for (var i 0) (i <= 4) (i += 1)
        (sum += i)
      )
      sum
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 10
    end

    it "
      # function should work
      (fn f _ 1)
      (f)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # passing argument to function should work
      (fn f a a)
      (f 1)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # Passing multiple arguments should work
      (fn f [a b] (a + b))
      (f 1 2)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 3
    end

    it "
      # Scope inheritance should work
      (fn g _ 1)
      (fn f _ (g))
      (f)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # varargs should work
      (fn f a... a)
      (f 1 2)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == [1, 2]
    end

    it "
      # varargs should work
      (fn f [a b...] b)
      (f 1 2 3)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == [2, 3]
    end

    it "
      # varargs should work
      (fn f [a... b] b)
      (f 1 2 3)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 3
    end

    it "
      # return should work
      (fn f _
        (return 1)
        2
      )
      (f)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # fn...if should work
      (fn f [a b c]
        (if a b else c)
      )
      (f true 1 2)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # fn...if should work
      (fn f [a b c]
        (if a b else c)
      )
      (f false 1 2)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 2
    end

    it "
      # fn...for should work
      (fn f a
        (var sum 0)
        (for (var i 0) (i <= a) (i += 1)
          (sum += i)
        )
        sum
      )
      (f 4)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 10
    end

    it "
      # decorator should work
      (fn f a a)
      +f 1
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # decorator should work
      (fn f a a)
      [+f 1 2]
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == [1, 2]
    end

    it "
      # class/method should work
      (class A
        (method test)
      )
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      klass = app.run
      klass.methods.size.should == 1
    end

    it "
      # class, new, method invocation should work
      (class A
        (method test _ 1)
      )
      ((new A) .test)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # class initialization should work
      (class A
        (init a
          (@a = a)
        )
        (method test _ @a)
      )
      ((new A 1) .test)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # (.test) should work
      (class A
        (method test _ 1)
        (method test2 _ (.test))
      )
      ((new A) .test2)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # self should work
      (class A
        (method test _ self)
      )
      (var a (new A))
      (a == (a .test))
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == true
    end

    it "
      # property access should work
      (class A
        (method test _
          (@a = 1)
          @a
        )
      )
      ((new A) .test)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # super should work
      (class A
        (method test _
          1
        )
      )
      (class B extend A
        (method test _
          (super)
        )
      )
      ((new B) .test)
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end

    it "
      # module should work
      (module M
        (method test)
      )
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      m = app.run
      m.methods.size.should == 1
    end

    it "
      # init is not allowed in a module
      # Ideally this should be caught during the compilation phase.
      # However because Gene is a dynamic and flexible language, it might be too hard to handle all different scenarios.
      (module M
        (init)
      )
    " do
      lambda {
        mod = @compiler.parse_and_compile example.description
        app = Application.new(mod)
        app.run
      }.should raise_error
    end

    it "
      # assert should work
      (assert false 'Houston, we have a problem')
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      lambda {
        app.run
      }.should raise_error('Houston, we have a problem')
    end

    it "
      # assert should work
      (assert true 'Houston, we have a problem')
      1
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end
  end

  describe "Complex expressions" do
    testcases = %Q~
      (assert (1 == 1))
    ~

    focus = testcases.include?('!focus!')
    if focus
      puts "\nRun focused tests only!\n"
    end

    testcases.split("\n\n").each do |testcase|
      next if focus and not testcase.include? '!focus!'

      it testcase do
        pending if testcase.index('!pending!') and not testcase.include? '!focus!'

        mod = @compiler.parse_and_compile testcase
        app = Application.new(mod)
        app.run
      end
    end
  end
end