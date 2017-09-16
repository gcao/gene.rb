require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "File" do
  before do
    @application = Gene::Lang::Application.new
    @interpreter = Gene::Lang::Interpreter.new @application.root_context
  end

  it "(File .read 'spec/data/test.txt')" do
    pending
    result = @interpreter.parse_and_process(example.description)
    result.should == "Test\nTest 2"
  end
end
