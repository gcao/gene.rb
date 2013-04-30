require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  {
    '""'       => "",
    '()'       => [],
    '("a")'    => ["a"],
    '(a)'      => [Gene::Entity.new('a')],
    '(a b)'    => [Gene::Entity.new('a'), Gene::Entity.new('b')],
    '(a [b])'  => [Gene::Entity.new('a'), [Gene::Entity.new('[]'), Gene::Entity.new('b')]],
    '[a]'      => [Gene::Entity.new('[]'), Gene::Entity.new('a')],
    '[[a]]'    => [Gene::Entity.new('[]'), [Gene::Entity.new('[]'), Gene::Entity.new('a')]],
    '(\[\] a)' => [Gene::Entity.new('[]'), Gene::Entity.new('a')],
    '{a}'      => [Gene::Entity.new('{}'), Gene::Entity.new('a')],
  }.each do |input, result|
    it "#{input} should work" do
      Gene::Parser.new(input).parse.should == result
    end
  end
end
