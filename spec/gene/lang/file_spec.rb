require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "File" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "(File .read 'spec/data/test.txt')" do
    pending
    result = @application.parse_and_process(example.description)
    result.should == "Test\nTest 2"
  end
end
