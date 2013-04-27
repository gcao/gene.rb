require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  it "should work" do
    input  = ""
    result = []
    Gene::Parser.new.parse(input).should == result
  end
end
