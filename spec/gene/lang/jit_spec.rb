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
    p mod
    app = Application.new(mod)
    app.run.should == 1
  end

  it "
    (if false 1 else 2)
  " do
    pending
    mod = @compiler.parse_and_compile example.description
    p mod
    app = Application.new(mod)
    app.run.should == 2
  end
end

describe "JIT Virtual Machine" do
  it "should run compiled block" do
    pending
    block = CompiledBlock.new([
      [WRITE, 'a', 1],
      [READ, 'a'],
    ])

    app = Application.new(CompiledModule.new(block))
    app.run.should == 1
  end
end