require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'gene/macro/interpreter'

describe Gene::Macro::Interpreter do
  before do
    @interpreter = Gene::Macro::Interpreter.new
  end

  describe "Variable" do
    it "(#def a 'value') \#@a" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end
  end
end
