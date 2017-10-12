require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Class" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "
    (class A)
    ((A .is_sub_class A) == true)
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "
    (class A)
    (class B (extend A))
    ((B .is_sub_class A) == true)
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "
    (class A)
    (class B)
    ((A .is_sub_class B) == false)
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end

  it "
    (class A)
    (class B (extend A))
    (class C (extend B))
    ((C .is_sub_class A) == true)
  " do
    result = @application.parse_and_process(example.description)
    result.should be_true
  end
end

