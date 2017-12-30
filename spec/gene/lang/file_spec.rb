require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "File" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "
    (assert ((File/read 'spec/data/test.txt') == \"Test\nTest 2\"))
  " do
    @application.parse_and_process(example.description)
  end
end
