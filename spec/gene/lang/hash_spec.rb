require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Hash" do
  before do
    @interpreter = Gene::Lang::Interpreter.new
    @interpreter.load_core_libs
  end

  it "({} .size)" do
    result = @interpreter.parse_and_process(example.description)
    result.should == 0
  end
end
