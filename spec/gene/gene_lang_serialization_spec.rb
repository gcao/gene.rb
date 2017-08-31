require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Lang do
  before do
    @interpreter = Gene::Lang::Interpreter.new
  end

  describe "serialization" do
    it "_scope" do
      result = Gene::Lang.serialize @interpreter.parse_and_process(example.description)
      result.should == '{"#class": "Gene::Lang::Scope", "parent": null, "variables": {}, "arguments": []}'
    end

    it "(class A)" do
      result = Gene::Lang.serialize @interpreter.parse_and_process(example.description)
      result.should == '{"#class": "Gene::Lang::Class", "name": "A", "instance_methods": {}, "properties": {}}'
    end
  end

  describe "deserialization" do
    it "_scope" do
      serialized = Gene::Lang.serialize @interpreter.parse_and_process(example.description)
      result = Gene::Lang.deserialize serialized
      result.class.should == Gene::Lang::Scope
    end
  end
end
