require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "Jit" do
  it "should work" do
    block = CompiledBlock.new([
      [WRITE, 'a', 1],
      [READ, 'a'],
    ])

    app = Application.new(CompiledModule.new(block))
    app.run.should == 1
  end
end
