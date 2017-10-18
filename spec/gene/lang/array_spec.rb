require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Array
  Array is created as a native array in the hosted language
  When a method invocation occurs to an array, a proxy object is created on the fly
  The proxy object is an instance of Gene::Lang::Array
  This approach is applied on all literals and hash objects as well
" do

  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "((Array .parent_class) == Object)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "(([] .is Object) == true)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "(([] .is Array) == true)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "(([] .is Hash) == false)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "
    (fn f _ [])
    (def a (f))
    (def b (f))
    (($invoke a 'object_id') != ($invoke b 'object_id'))
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "(([1] .size) == 1)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "(([1] .get 0) == 1)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "([1] .get 1)" do
    result = @application.parse_and_process(example.description)
    result.should == nil
  end

  it "(([1] .any (fnx item (item == 1))) == true)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "(([1] .any (fnx item (item == 2))) == false)" do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "([1 [2]] .flatten)" do
    result = @application.parse_and_process(example.description)
    result.should == [1, 2]
  end

  it "
    (def sum 0)
    # each is a method defined in Gene::Lang::Array
    ([1 2] .each
      (fnx item
        (sum += item)
      )
    )
    sum
  " do
    result = @application.parse_and_process(example.description)
    result.should == 3
  end
end
