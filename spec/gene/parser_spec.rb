require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  it "should work" do
    input  = "[a]"
    result = [Gene::Type::Ident.new('a')]
    Gene::Parser.new(input).parse.should == result
  end
end
