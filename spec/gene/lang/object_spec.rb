require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Object" do
  before do
    @interpreter = Gene::Lang::Interpreter.new
    @interpreter.load_core_libs
  end

  it "
    (let o (new Object))
    (o .set 'x' 1)
    o
  " do
    result = @interpreter.parse_and_process(example.description)
    result.get('x').should == 1
  end
end
