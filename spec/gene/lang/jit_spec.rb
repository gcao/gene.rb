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
    (1 + 2)
  " do
    pending
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
end