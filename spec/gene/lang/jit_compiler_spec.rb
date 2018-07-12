require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "JIT Compiler" do
  before do
    @compiler = Compiler.new
  end

  it "
    (var a)
  " do
    result = @compiler.parse_and_compile example.description
    result.primary_block.instructions.should == [
      [INIT],
      [DEF_MEMBER, 'a', nil, {'type' => 'scope'}],
      [CALL_END],
    ]
  end

  it "
    a
  " do
    result = @compiler.parse_and_compile example.description
    result.primary_block.instructions.should == [
      [INIT],
      [GET_MEMBER, 'a'],
      [CALL_END],
    ]
  end
end