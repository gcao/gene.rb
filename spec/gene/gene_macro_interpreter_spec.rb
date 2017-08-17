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

  describe "map" do
    it "(#map [1 2] value #do [##value])" do
      result = @interpreter.parse_and_process(example.description)
      result.should == [[1], [2]]
    end

    it "(#map [1 2] value index #do [##index ##value])" do
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

  describe "Environment/file system/etc" do
    it "(#env HOME)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == ENV['HOME']
    end

    it "#cwd" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Dir.pwd
    end

    it "(#ls)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Dir.entries(Dir.pwd)
    end

    it "(#read 'spec/data/test.txt')" do
      result = @interpreter.parse_and_process(example.description)
      result.should == "Test\nTest 2"
    end
  end

  describe "get" do
    it "(#get [1 2 3] 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end

    it "(#get {a : 'va', b : 'vb'} b)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'vb'
    end

    it "(#get [1 {a : 'value'} 3] 1 a)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#get {a : 'value', b : [1 2 3]} b 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end
  end
end
