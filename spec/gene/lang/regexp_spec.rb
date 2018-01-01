require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Regular Expressions" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
  end

  it "
    (assert (#/a/ =~ 'a'))
  " do
    @application.parse_and_process(example.description)
  end

  it "
    (assert ((regexp 'a') =~ 'a'))
  " do
    @application.parse_and_process(example.description)
  end

  it "
    (assert ((regexp ^^ignore-case 'a') =~ 'A'))
  " do
    @application.parse_and_process(example.description)
  end
end
