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

  it "read file" do
    file_name = 'gene_test.txt'
    content   = 'This is a test file'
    path      = "/tmp/#{file_name}"

    File.open path, 'w' do |file|
      file.write content
    end

    data = Gene::FileSystem.read path

    data.class.should == Gene::Group
    data.first.should == Gene::FileSystem::FILE
    data[1].should == file_name
    data[2].should == content
  end

  it "read dir" do
    pending
  end

  it "read dir and file" do
    pending
  end

  describe "write" do
    it "(dir test (file test.txt \"This is a test file\"))" do
      data   = Gene::Parser.new(example.description).parse
      to_dir = Dir.mktmpdir('gene')

      Gene::FileSystem.write to_dir, data

      File.directory?("#{to_dir}/test").should == true
      File.file?("#{to_dir}/test/test.txt").should == true
      File.read("#{to_dir}/test/test.txt").should == "This is a test file"
    end
  end

end
