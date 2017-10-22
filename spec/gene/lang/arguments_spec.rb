require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Arguments do
  before  do
    @application = Gene::Lang::Application.new
    @matcher = Gene::Lang::Matcher.new
    @matcher.from_array [
      Gene::Types::Symbol.new('arg1'),
      Gene::Types::Symbol.new('arg2...'),
      Gene::Types::Symbol.new('^^attr1'),
    ]
  end

  it "should work" do
    arguments = Gene::Lang::Arguments.new
    arguments.data = [1, 2, 3]
    arguments.matcher = @matcher
    arguments.get_member('arg1').should == 1
    arguments.get_member('arg2').should == [2, 3]
  end

  it "prop matcher should work" do
    arguments = Gene::Lang::Arguments.new
    arguments.set 'attr1', 'a'
    arguments.matcher = @matcher
    arguments.get_member('attr1').should == 'a'
  end

  it "`set_member` should work" do
    arguments = Gene::Lang::Arguments.new
    arguments.data = [1, 2]
    arguments.matcher = @matcher
    arguments.set_member('arg1', 3)
    arguments.data.should == [3, 2]
  end

  it "`set_member` should work for expandable data matcher" do
    arguments = Gene::Lang::Arguments.new
    arguments.data = [1, 2, 3]
    arguments.matcher = @matcher
    arguments.set_member('arg2', [3, 4])
    arguments.data.should == [1, 3, 4]
  end

  it "`set_member` should work for prop_matcher" do
    arguments = Gene::Lang::Arguments.new
    arguments.set 'attr1', 'a'
    arguments.matcher = @matcher
    arguments.set_member('attr1', 'b')
    arguments.get('attr1').should == 'b'
  end
end
