require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'gene/macro/interpreter'

describe Gene::Macro::Interpreter do
  before do
    @interpreter = Gene::Macro::Interpreter.new
  end

  describe "Variable" do
    it "(#def a 'value')" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "(#def-retain a 'value')" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#def a 'value') ##a" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#def-multi [a 1] [b 2] [c])" do
      pending "Verify a=1, b=2 c=undefined"
    end
  end

  describe "fn" do
    it "(#fn f [a] ##a)(##f 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#fn f a ##a)(##f 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end

  describe "each" do
    it "(#each [1 2] [##_index ##_value])" do
      result = @interpreter.parse_and_process(example.description)
      result.should == [[0, 1], [1, 2]]
    end
  end

  describe "if" do
    it "(#if true 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#if false 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end

    it "(#if true #then (#def a 1) ##a)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#if false #then (#def a 1) ##a #else (#def a 2) ##a)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end
  end
end
