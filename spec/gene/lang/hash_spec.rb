require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Hash" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "# `{}` will always create a new Hash object
    (fn f _ {})
    (var a (f))
    (var b (f))
    (($invoke a 'object_id') != ($invoke b 'object_id'))
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "(({} .size) == 0)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end
end
