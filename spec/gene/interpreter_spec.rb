require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Interpreter do

  before do
    @interpreter = Gene::Interpreter.new
    @interpreter.handlers = [
      Gene::Handlers::ClassHandler.new(@interpreter),
      Gene::Handlers::MethodHandler.new(@interpreter),
      Gene::Handlers::Base.new(@interpreter)
    ]
  end

  # Copy individual tests to below and run to make debug easier
  # in vim command line, enter :rspec %:11
  {
  }.each do |input, result|
    it "process #{input} should work !!!" do
      parsed = Gene::Parser.new(input).parse
      Gene::Interpreter.new.run(parsed).should == result
    end
  end

  {
    '1'          => 1,
    '"a"'        => "a",
    'null'       => nil,
    '[]'         => [],
    '[1]'        => [1],
    '{}'         => {},
    '{1 : 2}'    => {1 => 2},
    '{() : 2}'   => {},
    '()'         => Gene::NOOP,
    '[()]'       => [],
    '(1)'        => Gene::Group.new(1),
    '(1 2)'      => Gene::Group.new(1, 2),
    '(1 ())'     => Gene::Group.new(1),
    #'(($$ let a 1) ($$ + a 1))' => 2,
  }.each do |input, result|
    it "process #{input} should work" do
      parsed = Gene::Parser.new(input).parse
      #@interpreter.run(parsed).should == result
    end
  end

  it "process (class A) should work" do
    parsed = Gene::Parser.new('(class A)').parse
    result = eval @interpreter.run(parsed)
    result.class.should == Class
    result.name.should  == 'A'
  end

  it "process (@a = 1) should work" do
    parsed = Gene::Parser.new('(@a = 1)').parse
    result = eval @interpreter.run(parsed)
    @a.should == 1
  end

  it "process (class A (@a = 1)) should work" do
    parsed = Gene::Parser.new('(class A (@a = 1))').parse
    output = @interpreter.run(parsed)
    result = eval output
    result.name.should == 'A'
    result.instance_variable_get(:@a).should == 1
  end

  it "process (def meth 1) should work" do
    parsed = Gene::Parser.new('(def meth 1)').parse
    result = eval @interpreter.run(parsed)
    meth.should == 1
  end

  it "process (class A (def meth 1)) should work" do
    parsed = Gene::Parser.new('(class A (def meth 1))').parse
    output = @interpreter.run(parsed)
    result = eval output
    result.name.should == 'A'
    result.new.meth.should == 1
  end

  describe "self.normalize" do
    it "should work" do
      Gene::Interpreter.normalize(Gene::Group.new(Gene::NOOP)).should == Gene::Group.new()
    end
  end
end
