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

  it "# `[]` will always create a new Array object
    (fn f _ [])
    (var a (f))
    (var b (f))
    +assert (($invoke a 'object_id') != ($invoke b 'object_id'))
  " do
    @application.parse_and_process(example.description)
  end

  it "+assert ((Array .parent_class) == Object)" do
    @application.parse_and_process(example.description)
  end

  it "+assert (([] .is Object) == true)" do
    @application.parse_and_process(example.description)
  end

  it "+assert (([] .is Array) == true)" do
    @application.parse_and_process(example.description)
  end

  it "+assert (([] .is Hash) == false)" do
    @application.parse_and_process(example.description)
  end

  it "
    (fn f _ [])
    (var a (f))
    (var b (f))
    +assert (($invoke a 'object_id') != ($invoke b 'object_id'))
  " do
    @application.parse_and_process(example.description)
  end

  it "+assert (([1] .size) == 1)" do
    @application.parse_and_process(example.description)
  end

  it "+assert (([1] .get 0) == 1)" do
    @application.parse_and_process(example.description)
  end

  it "+assert (([1] .get 1) == undefined)" do
    @application.parse_and_process(example.description)
  end

  it "+assert (([1] .any (fnx item (item == 1))) == true)" do
    @application.parse_and_process(example.description)
  end

  it "+assert (([1 2] .select (fnx item (item > 1))) == [2])" do
    @application.parse_and_process(example.description)
  end

  it "+assert (([1 [2]] .flatten) == [1 2])" do
    @application.parse_and_process(example.description)
  end

  it "# `each` should work
    (var sum 0)
    ([1 2] .each
      (fnx item
        (sum += item)
      )
    )
    +assert (sum == 3)
  " do
    @application.parse_and_process(example.description)
  end
end
