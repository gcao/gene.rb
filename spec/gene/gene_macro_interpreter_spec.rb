require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Macro::Interpreter do
  before do
    @interpreter = Gene::Macro::Interpreter.new
  end

  describe "var: create or overwrite variable in current scope" do
    it "(#var a 'value') # returns IGNORE" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "(#var a 'value'){^a [1 ##a]}" do
      result = @interpreter.parse_and_process(example.description)
      result['a'][1].should == 'value'
    end

    it "(#var a 'value')(test ^attr ##a ##a)" do
      result = @interpreter.parse_and_process(example.description)
      result['attr'].should == 'value'
      result.data[0].should == 'value'
    end

    it "(#var-retain a 'value')" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#var a 'value') ##a" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#var-multi [a 1] [b 2] [c])" do
      pending "Verify a=1, b=2 c=undefined"
    end
  end

  describe "let: create or overwrite variable" do
    it "(#let a 'value') # returns IGNORE" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "(#let a 'value'){^a [1 ##a]}" do
      result = @interpreter.parse_and_process(example.description)
      result['a'][1].should == 'value'
    end

    it "(#let a 'value')(test ^attr ##a ##a)" do
      result = @interpreter.parse_and_process(example.description)
      result['attr'].should == 'value'
      result.data[0].should == 'value'
    end

    it "(#let-retain a 'value')" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#let a 'value') ##a" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#let-multi [a 1] [b 2] [c])" do
      pending "Verify a=1, b=2 c=undefined"
    end
  end

  describe "var vs let" do
    it "(#var a 'old') (#fn f _ (#var a 'new')) (##f) ##a" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'old'
    end

    it "(#var a 'old') (#fn f _ (#let a 'new')) (##f) ##a" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'new'
    end
  end

  describe "fn: function" do
    it "(#fn f a) # returns IGNORE" do
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

    it "(#fn f [] (#return 1) 2)(##f)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    # _ is a placeholder for arguments, will be ignored
    it "(#fn f _ ##_)(##f 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == nil
    end
  end

  describe "fnx: anonymous function" do
    it "(#fnx) # returns an anonymous function" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Macro::Function
    end

    it "(#var fa (#fnx a ##a))(##fa 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#var fa (#fnx [a] ##a))(##fa 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    # _ is a placeholder for arguments, will be ignored
    it "(#var fa (#fnx _ ##_))(##fa 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == nil
    end
  end

  describe "fnxx: anonymous dummy function" do
    it "(#fnxx) # returns an anonymous dummy function" do
      result = @interpreter.parse_and_process(example.description)
      result.class.should == Gene::Macro::Function
    end

    it "(#var fa (#fnxx ##_))(##fa 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == nil
    end
  end

  describe "do: execute statements, return result of last executed statement" do
    it "(#do (#var a 1) ##a)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end
  end

  describe "map: transform array or hash" do
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

    it "(#if true #then (#var a 1) ##a)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#if false #then (#var a 1) ##a #else (#var a 2) ##a)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end
  end

  describe "get: access data inside gene/array/hash etc" do
    it "(#get [1 2 3] 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end

    it "(#get {^a 'va', ^b 'vb'} b)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'vb'
    end

    it "(#get [1 {^a 'value'} 3] 1 a)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 'value'
    end

    it "(#get {^a 'value', ^b [1 2 3]} b 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end
  end

  describe "for: create for-loop" do
    it "(#for (#var i 0)(#le ##i 100)(#incr i) #do ##i) # returns IGNORE" do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::UNDEFINED
    end

    it "(#for (#var i 0)(#le ##i 100)(#incr i) #do ##i) ##i" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 101
    end

    it "(#for (#var i 0)(#le ##i 100) #do (#incr i)) ##i" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 101
    end

    it "(#var i 0)(#for _ (#le ##i 100) #do (#incr i)) ##i" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 101
    end

    it "(#for (#var i 0)(#lt ##i 5)(#incr i) #do (#yield ##i))" do
      result = @interpreter.parse_and_process(example.description)
      result.should == [0, 1, 2, 3, 4]
    end

    it "
      (#for (#var i 0)(#lt ##i 2)(#incr i) #do
        (#for (#var j 0)(#lt ##j 2)(#incr j) #do
          (#yield ##i)
        )
      )
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == [0, 0, 1, 1]
    end

    it "
      [
        (#for (#var i 0)(#lt ##i 2)(#incr i) #do
          (#for (#var j 0)(#lt ##j 2)(#incr j) #do
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
        (#for (#var i 0)(#lt ##i 2)(#incr i) #do
          (#for (#var j 0)(#lt ##j 2)(#incr j) #do
            (#yield ##i)
          )
        )
      )
    " do
      result = @interpreter.parse_and_process(example.description)
      result.should == Gene::Parser.parse("(x 0 0 1 1)")
    end
  end

  describe "loop: simplest loop" do
    it "
      (#loop
        (##incr x)
        (#if (##x > 4) #break)
      )
      ##x
    " do
      pending "loop/break not implemented"
      result = @interpreter.parse_and_process(example.description)
      result.should == 10
    end
  end

  describe "comparison" do
    it "#eq" do
      @interpreter.parse_and_process("(#eq 1 1)").should == true
      @interpreter.parse_and_process("(#eq 1 2)").should == false
      @interpreter.parse_and_process("(#eq 'a' 'a')").should == true
      @interpreter.parse_and_process("(#eq 'a' 'b')").should == false
    end

    it "#ne" do
      @interpreter.parse_and_process("(#ne 1 1)").should == false
      @interpreter.parse_and_process("(#ne 1 2)").should == true
      @interpreter.parse_and_process("(#ne 'a' 'a')").should == false
      @interpreter.parse_and_process("(#ne 'a' 'b')").should == true
    end

    it "#lt" do
      @interpreter.parse_and_process("(#lt 1 1)").should == false
      @interpreter.parse_and_process("(#lt 1 2)").should == true
      @interpreter.parse_and_process("(#lt 'a' 'a')").should == false
      @interpreter.parse_and_process("(#lt 'a' 'b')").should == true
    end

    it "#le" do
      @interpreter.parse_and_process("(#le 2 1)").should == false
      @interpreter.parse_and_process("(#le 1 1)").should == true
      @interpreter.parse_and_process("(#le 1 2)").should == true
      @interpreter.parse_and_process("(#le 'b' 'a')").should == false
      @interpreter.parse_and_process("(#le 'a' 'a')").should == true
      @interpreter.parse_and_process("(#le 'a' 'b')").should == true
    end

    it "#gt" do
      @interpreter.parse_and_process("(#gt 1 1)").should == false
      @interpreter.parse_and_process("(#gt 2 1)").should == true
      @interpreter.parse_and_process("(#gt 'a' 'a')").should == false
      @interpreter.parse_and_process("(#gt 'b' 'a')").should == true
    end

    it "#ge" do
      @interpreter.parse_and_process("(#ge 2 1)").should == true
      @interpreter.parse_and_process("(#ge 1 1)").should == true
      @interpreter.parse_and_process("(#ge 1 2)").should == false
      @interpreter.parse_and_process("(#ge 'b' 'a')").should == true
      @interpreter.parse_and_process("(#ge 'a' 'a')").should == true
      @interpreter.parse_and_process("(#ge 'a' 'b')").should == false
    end
  end

  describe "operations" do
    it "(#add 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 3
    end

    it "(#add ##i 1)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#add 1 ##i)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#sub 1 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == -1
    end

    it "(#mul 2 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 4
    end

    it "(#div 2 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#var i 0)(#incr i)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#incr i)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 1
    end

    it "(#var i 0)(#incr i 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == 2
    end

    it "(#var i 0)(#decr i)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == -1
    end

    it "(#decr i)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == -1
    end

    it "(#var i 0)(#decr i 2)" do
      result = @interpreter.parse_and_process(example.description)
      result.should == -2
    end
  end

  describe "inputs" do
    it "(#get #input a)" do
      input = Gene::Parser.parse "{^a 'va'}"
      result = @interpreter.parse_and_process(example.description, input)
      result.should == 'va'
    end

    it "(#get #input b)" do
      input = Gene::Parser.parse "{^a 'va'}"
      result = @interpreter.parse_and_process(example.description, input)
      pending
      result.should == nil
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

  describe "complex macros" do
    it '
      (#fn times [n callback]
        (#for (#var i 0)(#lt ##i ##n)(#incr i) #do (##callback))
      )
      (#var result 0)
      (##times 2 (#fnxx (#incr result 2)))
      ##result
    ' do
      result = @interpreter.parse_and_process(example.description)
      result.should == 4
    end
  end
end
