require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "JIT" do
  before do
    @compiler = Compiler.new
  end

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
    (var a 1)
    a
  " do
    mod = @compiler.parse_and_compile example.description
    app = Application.new(mod)
    app.run.should == 1
  end

  it "
    (if true 1 else 2)
  " do
    mod = @compiler.parse_and_compile example.description
    app = Application.new(mod)
    app.run.should == 1
  end

  it "
    (if false 1 else 2)
  " do
    mod = @compiler.parse_and_compile example.description
    app = Application.new(mod)
    app.run.should == 2
  end

  it "
    (loop (if true break))
    1
  " do
    mod = @compiler.parse_and_compile example.description
    app = Application.new(mod)
    app.run.should == 1
  end

  it "
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
    (fn f _ 1)
    (f)
  " do
    mod = @compiler.parse_and_compile example.description
    app = Application.new(mod)
    app.run.should == 1
  end

  it "
    (fn f a a)
    (f 1)
  " do
    mod = @compiler.parse_and_compile example.description
    app = Application.new(mod)
    app.run.should == 1
  end

  it "
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
end