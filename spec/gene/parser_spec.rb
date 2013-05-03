require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gene::Parser do
  {
    '""'       => "",
    '"a"'      => "a",
    '1'        => 1,
    '-1'       => -1,
    '1.0'      => 1.0,
    '-1.0'     => -1.0,
    'true'     => true,
    'false'    => false,
    'null'     => nil,
    'a'        => Gene::Entity.new('a'),
    '\\('      => Gene::Entity.new('('),
    '()'       => Gene::Group.new(),
    '("a")'    => Gene::Group.new("a"),
    '(a)'      => Gene::Group.new(Gene::Entity.new('a')),
    '(a b)'    => Gene::Group.new(Gene::Entity.new('a'), Gene::Entity.new('b')),
    '(a (b))'  => Gene::Group.new(Gene::Entity.new('a'), Gene::Group.new(Gene::Entity.new('b'))),
    '[a]'      => Gene::Group.new(Gene::Entity.new('[]'), Gene::Entity.new('a')),
    '(\[\] a)' => Gene::Group.new(Gene::Entity.new('[]'), Gene::Entity.new('a')),
    '[[a]]'    => Gene::Group.new(Gene::Entity.new('[]'), Gene::Group.new(Gene::Entity.new('[]'), Gene::Entity.new('a'))),
    '{}'       => Gene::Group.new(Gene::Entity.new('{}')),
    '(\{\})'   => Gene::Group.new(Gene::Entity.new('{}')),
    '{a b}'    => Gene::Group.new(Gene::Entity.new('{}'), Gene::Entity.new('a'), Gene::Entity.new('b')),
  }.each do |input, result|
    it "parse #{input} should work" do
      Gene::Parser.new(input).parse.should == result
    end
  end

  [
    '',
    '(',
    ')',
    '[(]',
    '[)]',
    'a b',
    '{a}',
    'a ()',
  ].each do |input|
    it "process #{input} should fail" do
      lambda {
        Gene::Parser.new(input).parse
      }.should raise_error(Gene::ParseError)
    end
  end

end
