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

    data.class.should == Gene::Types::Group
    data.first.should == Gene::FileSystem::FILE
    data[1].should == file_name
    data[2].should == content
  end

  it "read binary file" do
    data = Gene::FileSystem.read File.expand_path(File.dirname(__FILE__) + '/../data/test.gif')
    data.class.should == Gene::Types::Group
    data.first.should == Gene::FileSystem::FILE
    data[1].should == 'test.gif'
    content = data[2]
    pending "Binary file detection is not done"
    content.class.should == Gene::Types::Base64
  end

  it "read dir" do
    root = Dir.mktmpdir('gene')
    path = "#{root}/test"
    Dir.mkdir path

    data = Gene::FileSystem.read path

    data.class.should == Gene::Types::Group
    data.first.should == Gene::FileSystem::DIR
    data[1].should == 'test'
  end

  it "read dir and file" do
    root = Dir.mktmpdir('gene')
    dir  = "#{root}/test"
    Dir.mkdir dir
    File.open "#{dir}/test.txt", 'w' do |file|
      file.write "This is a test file"
    end

    data = Gene::FileSystem.read dir

    data.class.should == Gene::Types::Group
    data.first.should == Gene::FileSystem::DIR
    data[1].should == 'test'

    file_data = data[2]
    file_data[1].should == 'test.txt'
    file_data[2].should == "This is a test file"
  end

  describe "write" do
    it "(dir test (file test.txt \"This is a test file\"))" do
      to_dir = Dir.mktmpdir('gene')
      data   = Gene::Parser.new(example.description).parse

      Gene::FileSystem.write to_dir, data

      File.directory?("#{to_dir}/test").should == true
      File.file?("#{to_dir}/test/test.txt").should == true
      File.read("#{to_dir}/test/test.txt").should == "This is a test file"
    end
  end

end
