require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::JavascriptInterpreter do

  it "(class A)" do
    result = Gene::JavascriptInterpreter.parse_and_process(example.description)
    result.should == "function A(){\n}\n"
  end

end

