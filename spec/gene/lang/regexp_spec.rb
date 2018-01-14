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
    (assert (#/a/i =~ 'A'))
  " do
    @application.parse_and_process(example.description)
  end

  it "
    (assert (#/a/ == (regexp 'a')))
  " do
    @application.parse_and_process(example.description)
  end

  it "
    (assert (#/a/imx == (regexp ^^ignore_case ^^multi_line ^^extended 'a')))
  " do
    @application.parse_and_process(example.description)
  end
end
