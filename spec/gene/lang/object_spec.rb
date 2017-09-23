require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Object" do
  before do
    @application = Gene::Lang::Application.new
    @interpreter = Gene::Lang::Interpreter.new @application.root_context
    @interpreter.load_core_libs
  end

  it "# get/set should work
    (let o (new Object))
    (o .set 'x' 1)
    ((o .get 'x') == 1)
  " do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end

  it "# send should work
    (let o (new Object))
    (o .set 'x' 1)
    ((o .call 'get' 'x') == 1)
  " do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end
end
