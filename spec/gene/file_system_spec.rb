require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::FileSystem do

  before do
    @interpreter = Gene::FileSystem.new
    @interpreter.handlers = [
      Gene::FileSystem::DirHandler.new(@interpreter),
      Gene::FileSystem::FileHandler.new(@interpreter),
    ]
  end

  it "(file test.txt 'This is a test file')" do
    parsed = Gene::Parser.new(example.description).parse
    file = @interpreter.run(parsed)
    file.should =~ /test.txt$/
  end

  it "(dir test)" do
    parsed = Gene::Parser.new(example.description).parse
    dir = @interpreter.run(parsed)
    dir.should =~ /test$/
  end

  it "(dir test (file test.txt 'This is a test file'))" do
    parsed = Gene::Parser.new(example.description).parse
    dir = @interpreter.run(parsed)
    dir.should =~ /test$/
  end

end
