require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  {
    '""'       => "",
    '"a"'      => "a",
    '1'        => 1,
    '-1'       => -1,
    '1.0'      => 1.0,
    'true'     => true,
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

  [
    'a b',
  ].each do |input|
    it "#{input} should fail" do
      lambda {
        Gene::Parser.new(input).parse
      }.should raise_error(Gene::ParserError)
    end
  end

end
