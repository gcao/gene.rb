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

    it "(#def a 'value'){'a' : [1 ##a]}" do
      result = @interpreter.parse_and_process(example.description)
      result['a'][1].should == 'value'
    end

    it "(#def a 'value')(test ^attr ##a ##a)" do
      result = @interpreter.parse_and_process(example.description)
      result['attr'].should == 'value'
      result.data[0].should == 'value'
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
    it "(#fn f a)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "(#fn f [a] ##a)(##f 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#fn f a ##a)(##f 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    # _ is a placeholder for arguments, will be ignored
    it "(#fn f _ ##_)(##f 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == nil
    end
  end

  # anonymous function
  describe "fnx" do
    it "(#def fa (#fnx a ##a))(##fa 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#def fa (#fnx [a] ##a))(##fa 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    # _ is a placeholder for arguments, will be ignored
    it "(#def fa (#fnx _ ##_))(##fa 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == nil
    end
  end

  describe "do" do
    it "(#do (#def a 1) ##a)" do
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

    it "(#read spec/data/test.txt)" do
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

  describe "inputs" do
    it "(#get #input a)" do
      input = Gene::Parser.parse "{a : 'va'}"
      result = @interpreter.parse_and_process(example.description, input)
      result.should == 'va'
    end
  end

  describe "for" do
    it "(#for (#def i 0)(#le ##i 100)(#incr i) #do ##i)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "(#for (#def i 0)(#le ##i 100)(#incr i) #do ##i) ##i" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 101
    end

    it "(#for (#def i 0)(#le ##i 100) #do (#incr i)) ##i" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 101
    end

    it "(#def i 0)(#for _ (#le ##i 100) #do (#incr i)) ##i" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 101
    end

    it "(#for (#def i 0)(#lt ##i 5)(#incr i) #do (#yield ##i))" do
      result = @interpreter.parse_and_process(example.description)
      result.should == [0, 1, 2, 3, 4]
    end

    it "
    (#for (#def i 0)(#lt ##i 2)(#incr i) #do
      (#for (#def j 0)(#lt ##j 2)(#incr j) #do
        (#yield ##i)
      )
    )
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == [0, 0, 1, 1]
    end

    it "
    [
      (#for (#def i 0)(#lt ##i 2)(#incr i) #do
        (#for (#def j 0)(#lt ##j 2)(#incr j) #do
          (#yield ##i)
        )
      )
    ]
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::Parser.parse("[0 0 1 1]")
    end

    it "
    (x
      (#for (#def i 0)(#lt ##i 2)(#incr i) #do
        (#for (#def j 0)(#lt ##j 2)(#incr j) #do
          (#yield ##i)
        )
      )
    )
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::Parser.parse("(x 0 0 1 1)")
    end
  end

  describe "complex macros" do
    it '(#fn times [n stmts] (#def i 0) (#while (#le ##i ##n) (#do ##stmts)))(##times 2 1' do
      pending
      result = @interpreter.parse_and_process(example.description)
      result.should == 'va'
    end
  end
end
