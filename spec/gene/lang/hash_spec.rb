require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Hash" do
  before do
    @interpreter = Gene::Lang::Interpreter.new
    @interpreter.load_core_libs
  end

  it "
    (fn f _ {})
    (let a (f))
    (let b (f))
    (($invoke a 'object_id') != ($invoke b 'object_id'))
  " do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end

  it "({} .size)" do
    result = @interpreter.parse_and_process(example.description)
    result.should == 0
  end
end
