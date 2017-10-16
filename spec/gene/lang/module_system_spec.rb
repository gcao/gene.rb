require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Module system" do
  before do
    @file = __FILE__
    @dir  = File.dirname(@file)

    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "# `import` should work
    (import Test from './test')
    (((new Test) .test) == 'test result')
  " do
    result = @application.parse_and_process(example.description, dir: @dir, file: @file)
    result.should be_true
  end

  it "# `import` private member should NOT work
    (import private_x from './test')
  " do
    lambda {
      @application.parse_and_process(example.description, dir: @dir, file: @file)
    }.should raise_error
  end

  it "# `import` non-existant member should NOT work
    (import NotExist from './test')
  " do
    lambda {
      @application.parse_and_process(example.description, dir: @dir, file: @file)
    }.should raise_error
  end
end