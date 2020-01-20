require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "JIT" do
  before do
    @compiler = Compiler.new
    APP.reset
  end

  it "
    # import should work
    (import test_function from 'spec/gene/lang/test')
    (test_function)
  " do
    mod = @compiler.parse_and_compile example.description
    APP.run(mod).should == 1
  end

  it "
    # import with inheritance should work
    (fn f _ 1)
    (import call_f from 'spec/gene/lang/test'
      ^inherit ['f']
    )
    (call_f)
  " do
    mod = @compiler.parse_and_compile example.description
    APP.run(mod).should == 1
  end

  it "
    (fn f _ 1)
    (import call_f from 'spec/gene/lang/test')
    (call_f)
  " do
    mod = @compiler.parse_and_compile example.description
    lambda {
      APP.run(mod).should == 1
    }.should raise_error
  end
end
