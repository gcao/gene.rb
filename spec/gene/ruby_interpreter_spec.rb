require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::RubyInterpreter do
  before do
    @interpreter = Gene::RubyInterpreter.new
  end

  it "(class A)" do
    result = eval @interpreter.parse_and_process(example.description)
    result.class.should == Class
    result.name.should  == 'A'
  end

  it "(if true (@a = 1) false)" do
    eval @interpreter.parse_and_process(example.description)
    @a.should == 1
  end

  it "(if false false (@a = 1))" do
    eval @interpreter.parse_and_process(example.description)
    @a.should == 1
  end

  it "(#'' 1 2)" do
    result = eval @interpreter.parse_and_process(example.description)
    result.should == "12"
  end

  it "(@a = 1)" do
    eval @interpreter.parse_and_process(example.description)
    @a.should == 1
  end

  it "(@a = 'ab') (@a.length)" do
    result = @interpreter.parse_and_process(example.description) do |stmt|
      eval stmt
    end
    result.should == 2
  end

  it "(class A (@a = 1))" do
    result = eval @interpreter.parse_and_process(example.description)
    result.name.should == 'A'
    result.instance_variable_get(:@a).should == 1
  end

  it "(def meth [1 2 3])" do
    eval @interpreter.parse_and_process(example.description)
    meth.should == [1, 2, 3]
  end

  it "(def meth arg arg)" do
    eval @interpreter.parse_and_process(example.description)
    meth(1).should == 1
  end

  it "(def meth [arg1 arg2] arg2)" do
    eval @interpreter.parse_and_process(example.description)
    meth(1, 2).should == 2
  end

  it "(class A (def meth 1))" do
    result = eval @interpreter.parse_and_process(example.description)
    result.name.should == 'A'
    result.new.meth.should == 1
  end

  it "
    (module M
     (class Pair
      (attr_reader :first :second)
      (def initialize[first second]
       (@first = first)
       (@second = second)
      )
     )
    )
  " do
    eval @interpreter.parse_and_process(example.description)
    obj = M::Pair.new(1, 2)
    obj.first.should == 1
    obj.second.should == 2
  end

  it "
    (def do_this[first second [third 'default']]
      (#'' first second third)
    )
  " do
    eval @interpreter.parse_and_process(example.description)
    do_this(1, 2).should == "12default"
    do_this(1, 2, 3).should == "123"
  end

end

