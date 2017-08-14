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

    it "(#def a 'value' #retain)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#def a 'value') \#@a" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#defmulti [a 1] [b 2] [c])" do
      pending "Verify a=1, b=2 c=undefined"
    end
  end

  describe "fn" do
    it "(#fn f [a] a)(\#@f 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end
end
