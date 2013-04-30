require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  {
    "(a)" => [Gene::Entity.new('a')],
    "[a]" => ['[]', Gene::Entity.new('a')],
    "{a}" => ['{}', Gene::Entity.new('a')],
  }.each do |input, result|
    it "#{input} should work" do
      Gene::Parser.new(input).parse.should == result
    end
  end
end
