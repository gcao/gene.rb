require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'v8'

describe Gene::JavascriptInterpreter do
  before do
    @ctx = V8::Context.new
  end

  it "(class A)" do
    pending "ES6 not supported"
    result = @ctx.eval Gene::JavascriptInterpreter.parse_and_process(example.description)
    result.name.should == 'A'
  end

  it "(function test)" do
    result = @ctx.eval Gene::JavascriptInterpreter.parse_and_process(example.description)
    result.name.should == 'test'
  end

  it "(1 + 2)" do
    result = @ctx.eval Gene::JavascriptInterpreter.parse_and_process(example.description)
    result.should == 3
  end

  it "(var a = 1)" do
    @ctx.eval Gene::JavascriptInterpreter.parse_and_process(example.description)
    @ctx['a'].should == 1
  end

end

