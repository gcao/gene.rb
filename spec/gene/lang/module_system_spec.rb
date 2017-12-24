require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Module system" do
  before do
    @file = __FILE__
    @dir  = File.dirname(@file)

    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "# `import` not-exported-variable should NOT work
    (import x from './test')
  " do
    lambda {
      @application.parse_and_process(example.description, dir: @dir, file: @file)
    }.should raise_error
  end

  it "# `import` exported-variable should work
    (import y from './test')
    (assert (y == 200))
  " do
    @application.parse_and_process(example.description, dir: @dir, file: @file)
  end

  it "# `import` non-existant member should NOT work
    (import NotExist from './test')
  " do
    lambda {
      @application.parse_and_process(example.description, dir: @dir, file: @file)
    }.should raise_error
  end

  it "# Classes are exported by default
    (import TestClass from './test')
    (assert ((TestClass .class) == Class))
  " do
    @application.parse_and_process(example.description, dir: @dir, file: @file)
  end

  it "# Functions are exported by default
    (import test_function from './test')
    (assert ((test_function .class) == Function))
  " do
    @application.parse_and_process(example.description, dir: @dir, file: @file)
  end
end