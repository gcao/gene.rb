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
    @app.run_module(mod).should_not be_nil
  end

  describe "File" do
    it "
      # Read file
      (gene/File/read 'spec/data/test.txt')
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == "Test\nTest 2"
    end

    it "
      # Write file
      (gene/File/write '/tmp/test.txt' 'test')
      (gene/File/read  '/tmp/test.txt')
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == "test"
    end

    it "
      (gene/File/read_lines 'spec/data/test.txt')
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == ["Test\n", "Test 2"]
    end
  end

  describe "Env" do
    it "
      (gene/Env 'HOME')
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == ENV['HOME']
    end

    it "
      (gene/Env/set 'TEST' 'haha')
      (gene/Env 'TEST')
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == 'haha'
    end
  end

  describe "String" do
    it "
      ('abc' .length)
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == 3
    end

    it "
      ('a,b' .split ',')
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == ['a', 'b']
    end

    it "
      ('abc' .substr 1)
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == 'bc'
    end
  end

  describe "Array" do
    it "
      ([3] .length)
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == 1
    end

    it "
      (var sum 0)
      ([1 2] .each (fnx item (sum += item)))
      sum
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == 3
    end
  end

  describe "Hash" do
    it "
      ({^^a} .size)
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == 1
    end

    it "
      (var result '')
      ({^a '1' ^b '2'} .each
        (fnx [key val] (result += (key + val)))
      )
      result
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == "a1b2"
    end
  end

  describe "Http" do
    it "
      ((gene/Http/get 'https://github.com') .status)
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == '200'
    end

    it "
      ((gene/Http/get 'https://github.com') .body)
    " do
      mod = @compiler.parse_and_compile example.description
      @app.run_module(mod).should == '{}'
    end
  end
end
