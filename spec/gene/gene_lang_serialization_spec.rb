require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Lang do
  before do
    @interpreter  = Gene::Lang::Interpreter.new
    @serializer   = Gene::Lang::Serializer.new
    @deserializer = Gene::Lang::Deserializer.new
  end

  describe "Serializer" do
    it "(let a 1)" do
      result = @serializer.process Gene::Parser.parse(example.description)
      result.should == '(let a 1)'
    end

    it "(class A)" do
      result = @serializer.process @interpreter.parse_and_process(example.description)
      result.should == '{"#class": "Gene::Lang::Class", "name": "A", "instance_methods": {}, "properties": {}}'
    end

    it "_scope" do
      result = @serializer.process @interpreter.parse_and_process(example.description)
      result.should == '{"#class": "Gene::Lang::Scope", "parent": null, "variables": {}, "arguments": []}'
    end
  end

  describe "Deserializer" do
    it "(class A)" do
      serialized = @serializer.process @interpreter.parse_and_process(example.description)
      result     = @deserializer.process serialized
      result.class.should == Gene::Lang::Class
      result.name.should  == "A"
    end

    it "_scope" do
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
