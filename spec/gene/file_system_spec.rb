require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::FileSystem do

  before do
    @interpreter = Gene::FileSystem.new
    @interpreter.handlers = [
      Gene::FileSystem::DirHandler.new(@interpreter),
      Gene::FileSystem::FileHandler.new(@interpreter),
      Gene::Handlers::Base.new(@interpreter)
    ]
  end

  it "(file test.txt 'This is a test file')" do
    parsed = Gene::Parser.new(example.description).parse
    file = @interpreter.run(parsed)
    file.path.should =~ /test.txt$/
    # TODO check result
  end

end
