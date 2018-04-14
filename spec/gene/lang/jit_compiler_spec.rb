require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "Jit Compiler" do
  before do
    pending
    @compiler = Compiler.new
  end

  it "
    (var a)
  " do
    result = @compiler.parse_and_compile example.description
    result.primary_block.instructions.should == [
      [DEFINE, 'a'],
    ]
  end

  it "
    a
  " do
    result = @compiler.parse_and_compile example.description
    result.primary_block.instructions.should == [
      [READ, 'a'],
    ]
  end
end