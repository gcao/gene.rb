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

  it "(([1] .size) == 1)" do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end

  it "(([1] .get 0) == 1)" do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end

  it "(([1] .get 1) == undefined)" do
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
  end

  it "(([1 [2]] .flatten) == [1 2])" do
    pending
    result = @interpreter.parse_and_process(example.description)
    result.should be_true
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
