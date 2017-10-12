require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Hash" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "
    (fn f _ {})
    (def a (f))
    (def b (f))
    (($invoke a 'object_id') != ($invoke b 'object_id'))
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "({} .size)" do
    result = @application.parse_and_process(example.description)
    result.should == 0
  end
end
