require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Interpreter do

  before do
    @interpreter = Gene::Interpreter.new
    @interpreter.handlers = [
      Gene::Handlers::ClassHandler.new(@interpreter.context)
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
      @interpreter.run(parsed).should == result
    end
  end

  it "process (class A) should work" do
    parsed = Gene::Parser.new('(class A)').parse
    result = @interpreter.run(parsed)
    result.class.should == Class
    result.name.should  == 'A'
  end

  describe "self.normalize" do
    it "should work" do
      Gene::Interpreter.normalize(Gene::Group.new(Gene::NOOP)).should == Gene::Group.new()
    end
  end
end
