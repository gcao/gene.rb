require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Module system" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "
    (import Test from './test')
    (((new Test) .test) == 'test result')
  " do
    file = __FILE__
    dir  = File.dirname(file)
    result = @application.parse_and_process(example.description, dir: dir, file: file)
    result.should be_true
  end
end