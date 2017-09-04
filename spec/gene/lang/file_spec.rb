require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "File" do
  before do
    @interpreter = Gene::Lang::Interpreter.new
  end

  it "(File .read 'spec/data/test.txt')" do
    result = @interpreter.parse_and_process(example.description)
    result.should == "Test\nTest 2"
  end
end
