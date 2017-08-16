require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'gene/file_system'

describe Gene::FileSystem do
  before do
    @interpreter = Gene::FileSystem.new
  end

  it "(file test.txt 'This is a test file')" do
    file = @interpreter.parse_and_process(example.description)
    file.should =~ /test.txt$/
  end

  it "(dir test)" do
    dir = @interpreter.parse_and_process(example.description)
    dir.should =~ /test$/
  end

  it "(dir test (file test.txt 'This is a test file'))" do
    dir = @interpreter.parse_and_process(example.description)
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

    data.class.should == Gene::Types::Base
    data.type.should == Gene::FileSystem::FILE
    data.data[0].should == file_name
    data.data[1].should == content
  end

  it "read binary file" do
    data = Gene::FileSystem.read File.expand_path(File.dirname(__FILE__) + '/../data/test.gif')
    data.class.should == Gene::Types::Base
    data.type.should == Gene::FileSystem::FILE
    data.data[0].should == 'test.gif'
    content = data.data[1]
    pending "Binary file detection is not done"
    content.class.should == Gene::Types::Base64
  end

  it "read dir" do
    root = Dir.mktmpdir('gene')
    path = "#{root}/test"
    Dir.mkdir path

    data = Gene::FileSystem.read path

    data.class.should == Gene::Types::Base
    data.type.should == Gene::FileSystem::DIR
    data.data[0].should == 'test'
  end

  it "read dir and file" do
    root = Dir.mktmpdir('gene')
    dir  = "#{root}/test"
    Dir.mkdir dir
    File.open "#{dir}/test.txt", 'w' do |file|
      file.write "This is a test file"
    end

    data = Gene::FileSystem.read dir

    data.class.should == Gene::Types::Base
    data.type.should == Gene::FileSystem::DIR
    data.data[0].should == 'test'

    file_data = data.data[1]
    file_data.type.should == Gene::FileSystem::FILE
    file_data.data[0].should == 'test.txt'
    file_data.data[1].should == "This is a test file"
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
