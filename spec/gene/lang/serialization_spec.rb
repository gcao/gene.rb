require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang do
  before do
    @application  = Gene::Lang::Application.new
    @interpreter  = Gene::Lang::Interpreter.new @application.root_context
    @serializer   = Gene::Lang::Serializer.new
    @deserializer = Gene::Lang::Deserializer.new
  end

  describe "Serializer" do
    it "(let a 1)" do
      result = @serializer.process Gene::Parser.parse(example.description)
      result.should == '{"references": {}, "data": (let a 1)}'
    end

    it "(class A)" do
      result = @serializer.process @interpreter.parse_and_process(example.description)
      result.should == '{"references": {}, "data": {"#class": "Gene::Lang::Class", "name": "A", "methods": {}, "prop_descriptors": {}, "modules": []}}'
    end

    it "$scope" do
      result = @serializer.process @interpreter.parse_and_process(example.description)
      result.should == '{"references": {}, "data": {"#class": "Gene::Lang::Scope", "parent": null, "variables": {}, "arguments": []}}'
    end

    it "(fn f a (a + 1))" do
      obj = @interpreter.parse_and_process(example.description)
      result = @serializer.process obj
      pending
      # puts result and replace ... below with the real result, replace IDs with placeholders
      result.should == '...'.gsub("FUNC_ID", obj.object_id.to_s)
    end
  end

  describe "Deserializer" do
    it "(class A)" do
      serialized = @serializer.process @interpreter.parse_and_process(example.description)
      result     = @deserializer.process serialized
      result.class.should == Gene::Lang::Class
      result.name.should  == "A"
    end

    it "$scope" do
      serialized = @serializer.process @interpreter.parse_and_process(example.description)
      result     = @deserializer.process serialized
      result.class.should == Gene::Lang::Scope
    end

    it "(let a 1)" do
      serialized = @serializer.process Gene::Parser.parse(example.description)
      result     = @deserializer.process serialized
      result.class.should == Gene::Types::Base
    end

    it "(fn f)" do
      serialized = @serializer.process @interpreter.parse_and_process(example.description)
      result     = @deserializer.process serialized
      result.class.should == Gene::Lang::Function
      result.name.should == "f"
    end
  end
end
