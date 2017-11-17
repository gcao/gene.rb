require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Object" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "# get/set should work
    (var o (new Object))
    (o .set 'x' 1)
    ((o .get 'x') == 1)
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "# is should work
    (var o (new Object))
    (o .is Object)
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "# call should work
    (var o (new Object))
    (o .set 'x' 1)
    ((o .call 'get' 'x') == 1)
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end
end
