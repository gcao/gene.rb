require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Interpreter do

  before do
    @interpreter = Gene::Interpreter.new
    @interpreter.handlers = [
      Gene::Handlers::ArrayHandler.new(@interpreter),
      Gene::Handlers::HashHandler.new(@interpreter),
      Gene::Handlers::RangeHandler.new(@interpreter),
      Gene::Handlers::Base64Handler.new(@interpreter),
      Gene::Handlers::Ruby::ClassHandler.new(@interpreter),
      Gene::Handlers::Ruby::MethodHandler.new(@interpreter),
      Gene::Handlers::Ruby::StatementHandler.new(@interpreter),
    ]
  end

  # Copy individual tests to below and run to make debug easier
  # in vim command line, enter :!rspec %:20
  {
    #'(($$ let a 1) ($$ + a 1))' => 2,
  }.each do |input, result|
    it "process #{input} should work !!!" do
      parsed = Gene::Parser.new(input).parse
      @interpreter.run(parsed).should == result
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
    '(.. 1 3)'   => Range.new(1, 3),
    #'(($$ let a 1) ($$ + a 1))' => 2,
  }.each do |input, result|
    it input do
      parsed = Gene::Parser.new(input).parse
      @interpreter.run(parsed).should == result
    end
  end

  it "(base64 \"VGhpcyBpcyBhIHRlc3Q=\")" do
    parsed = Gene::Parser.new(example.description).parse
    result = @interpreter.run(parsed)
    result.class.should == Gene::Types::Base64
    result.data.should == "VGhpcyBpcyBhIHRlc3Q="
  end

  it "(class A)" do
    parsed = Gene::Parser.new(example.description).parse
    result = eval @interpreter.run(parsed)
    result.class.should == Class
    result.name.should  == 'A'
  end

  it "(@a = 1)" do
    parsed = Gene::Parser.new(example.description).parse
    result = eval @interpreter.run(parsed)
    @a.should == 1
  end

  it "(@a = 'ab') (@a .length)" do
    parsed = Gene::Parser.new(example.description).parse
    result = @interpreter.run(parsed) do |stmt|
      eval stmt
    end
    result.should == 2
  end

  it "(class A (@a = 1))" do
    parsed = Gene::Parser.new(example.description).parse
    output = @interpreter.run(parsed)
    result = eval output
    result.name.should == 'A'
    result.instance_variable_get(:@a).should == 1
  end

  it "(def meth 1)" do
    parsed = Gene::Parser.new(example.description).parse
    result = eval @interpreter.run(parsed)
    meth.should == 1
  end

  it "(def meth arg arg)" do
    parsed = Gene::Parser.new(example.description).parse
    output = @interpreter.run(parsed)
    result = eval output
    meth(1).should == 1
  end

  it "(def meth [arg1 arg2] arg2)" do
    parsed = Gene::Parser.new(example.description).parse
    output = @interpreter.run(parsed)
    result = eval output
    meth(1, 2).should == 2
  end

  it "(class A (def meth 1))" do
    parsed = Gene::Parser.new(example.description).parse
    output = @interpreter.run(parsed)
    result = eval output
    result.name.should == 'A'
    result.new.meth.should == 1
  end

  describe "self.normalize" do
    it "should work" do
      Gene::Interpreter.normalize(Gene::Types::Group.new(Gene::NOOP)).should == Gene::Types::Group.new()
    end
  end
end
