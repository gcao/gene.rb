require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Lang do
  before do
    @interpreter = Gene::Lang::Interpreter.new
  end

  it "serialization" do
    result = Gene::Lang.serialize @interpreter.scope
    result.should == '{"#class": "Gene::Lang::Scope", "parent": null, "variables": {}, "arguments": []}'
  end

  it "deserialization" do
    serialized = Gene::Lang.serialize @interpreter.scope
    result = Gene::Lang.deserialize serialized
    result.class.should == Gene::Lang::Scope
  end
end
