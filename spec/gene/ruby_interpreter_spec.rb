require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::RubyInterpreter do

  it "(class A)" do
    result = eval Gene::RubyInterpreter.parse_and_process(example.description)
    result.class.should == Class
    result.name.should  == 'A'
  end

  it "(if true (@a = 1) false)" do
    eval Gene::RubyInterpreter.parse_and_process(example.description)
    @a.should == 1
  end

  it "(if false false (@a = 1))" do
    eval Gene::RubyInterpreter.parse_and_process(example.description)
    @a.should == 1
  end

  it "('' 1 2)" do
    result = eval Gene::RubyInterpreter.parse_and_process(example.description)
    result.should == "12"
  end

  it "(@a = 1)" do
    eval Gene::RubyInterpreter.parse_and_process(example.description)
    @a.should == 1
  end

  it "(@a = 'ab') (@a .length)" do
    pending 'Gene::Stream processing logic is not finalized'
    result = Gene::RubyInterpreter.parse_and_process(example.description) do |stmt|
      eval stmt
    end
    result.should == 2
  end

  it "(class A (@a = 1))" do
    result = eval Gene::RubyInterpreter.parse_and_process(example.description)
    result.name.should == 'A'
    result.instance_variable_get(:@a).should == 1
  end

  it "(def meth [1 2 3])" do
    eval Gene::RubyInterpreter.parse_and_process(example.description)
    meth.should == [1, 2, 3]
  end

  it "(def meth arg arg)" do
    eval Gene::RubyInterpreter.parse_and_process(example.description)
    meth(1).should == 1
  end

  it "(def meth [arg1 arg2] arg2)" do
    eval Gene::RubyInterpreter.parse_and_process(example.description)
    meth(1, 2).should == 2
  end

  it "(class A (def meth 1))" do
    result = eval Gene::RubyInterpreter.parse_and_process(example.description)
    result.name.should == 'A'
    result.new.meth.should == 1
  end

  it "
    (class Pair
     (.attr_reader :first :second)
     (def initialize[first second]
      (@first = first)
      (@second = second)
     )
    )
  " do
    pending 'private method invocation is not figured out yet'
    code = Gene::RubyInterpreter.parse_and_process(example.description)
    klass = eval code
    obj = klass.new(1, 2)
    obj.first.should == 1
    obj.second.should == 2
  end

end

