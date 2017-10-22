require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::ArgumentsScope do
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
    arguments = Gene::Lang::Object.new
    arguments.data = [1, 2, 3]
    scope = Gene::Lang::ArgumentsScope.new arguments, @matcher
    scope.get_member('arg1').should == 1
    scope.get_member('arg2').should == [2, 3]
  end

  it "prop matcher should work" do
    arguments = Gene::Lang::Object.new
    arguments.set 'attr1', 'a'
    scope = Gene::Lang::ArgumentsScope.new arguments, @matcher
    scope.get_member('attr1').should == 'a'
  end

  it "`set_member` should work" do
    arguments = Gene::Lang::Object.new
    arguments.data = [1, 2]
    scope = Gene::Lang::ArgumentsScope.new arguments, @matcher
    scope.set_member('arg1', 3)
    arguments.data.should == [3, 2]
  end

  it "`set_member` should work for expandable data matcher" do
    arguments = Gene::Lang::Object.new
    arguments.data = [1, 2, 3]
    scope = Gene::Lang::ArgumentsScope.new arguments, @matcher
    scope.set_member('arg2', [3, 4])
    arguments.data.should == [1, 3, 4]
  end

  it "`set_member` should work for prop_matcher" do
    arguments = Gene::Lang::Object.new
    arguments.set 'attr1', 'a'
    scope = Gene::Lang::ArgumentsScope.new arguments, @matcher
    scope.set_member('attr1', 'b')
    arguments.get('attr1').should == 'b'
  end
end
