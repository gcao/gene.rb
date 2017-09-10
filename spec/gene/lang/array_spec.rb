require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Array" do
  before do
    @interpreter = Gene::Lang::Interpreter.new
    @interpreter.load_core_libs
  end

  it '
    Array is created as a native array in the hosted language
    When a method invocation occurs to an array, a proxy object is created on the fly
    The proxy object is an instance of Gene::Lang::Array
    This approach is applied on all literals and hash objects as well
  '

  it "(Array .parent_classes)" do
    pending
    result = @interpreter.parse_and_process(example.description)
    result.size.should == 1
    result[0].name.should == 'Object'
  end

  it "(([] .is Object) == true)" do
    pending
    result = @interpreter.parse_and_process(example.description)
    result.should == true
  end

  it "(([] .is Array) == true)" do
    pending
    result = @interpreter.parse_and_process(example.description)
    result.should == true
  end

  it "(([] .is Hash) == false)" do
    pending
    result = @interpreter.parse_and_process(example.description)
    result.should == true
  end

  it "
    (fn f _ [])
    (let a (f))
    (let b (f))
    (($invoke a 'object_id') != ($invoke b 'object_id'))
  " do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end

  it "(([1] .size) == 1)" do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end

  it "(([1] .get 0) == 1)" do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end

  it "([1] .get 1)" do
    result = @interpreter.parse_and_process(example.description)
    result.should == nil
  end

  it "([1] .any (fnx item (item == 1))) == true" do
    pending
    result = @interpreter.parse_and_process(example.description)
    result.should == true
  end

  it "([1] .any (fnx item (item == 2))) == false" do
    pending
    result = @interpreter.parse_and_process(example.description)
    result.should == true
  end

  it "([1 [2]] .flatten)" do
    result = @interpreter.parse_and_process(example.description)
    result.should == [1, 2]
  end

  it "
    (let sum 0)
    # each is a method defined in Gene::Lang::Array
    ([1 2] .each
      (fnx item
        (let sum (sum + item))
      )
    )
    sum
  " do
    result = @interpreter.parse_and_process(example.description)
    result.should == 3
  end
end
