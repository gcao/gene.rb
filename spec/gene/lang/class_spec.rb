require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Class" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  describe "`is_sub_class`" do
    it "
      (class A)
      +assert (A .is_sub_class A)
    " do
      @application.parse_and_process(example.description)
    end

    it "
      (class A)
      +assert (A .is_sub_class Object)
    " do
      @application.parse_and_process(example.description)
    end

    it "
      (class A)
      (class B extend A)
      +assert (B .is_sub_class A)
    " do
      @application.parse_and_process(example.description)
    end

    it "
      (class A)
      (class B)
      +assert ((A .is_sub_class B) == false)
    " do
      @application.parse_and_process(example.description)
    end

    it "
      (class A)
      (class B extend A)
      (class C extend B)
      +assert (C .is_sub_class A)
    " do
      @application.parse_and_process(example.description)
    end
  end
end
