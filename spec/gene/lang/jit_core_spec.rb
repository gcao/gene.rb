require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "JIT Core Lib" do
  before do
    @compiler = Compiler.new
    @app      = Application.new
    @app.load_core_lib
  end

  it "
    gene/Object
  " do
    mod = @compiler.parse_and_compile example.description
    @app.primary_module = mod
    @app.run.should_not be_nil
  end

  it "
    # Read file
    (gene/File/read 'spec/data/test.txt')
  " do
    mod = @compiler.parse_and_compile example.description
    @app.primary_module = mod
    @app.run.should == "Test\nTest 2"
  end

  it "
    # Write file
    (gene/File/write '/tmp/test.txt' 'test')
    (gene/File/read  '/tmp/test.txt')
  " do
    mod = @compiler.parse_and_compile example.description
    @app.primary_module = mod
    @app.run.should == "test"
  end
end
