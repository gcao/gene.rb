require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "Jit" do
  before do
    @compiler = Compiler.new
  end

  it "
    1
  " do
    mod = @compiler.parse_and_compile example.description
    p mod
    app = Application.new(mod)
    app.run.should == 1
  end

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
