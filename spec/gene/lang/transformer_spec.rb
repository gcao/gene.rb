require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Transformer do
  before do
    @parser      =
    @transformer = Gene::Lang::Transformer.new
  end

  describe "import" do
    it "(import a from 'test')" do
      parsed = Gene::Parser.parse(example.description)
      result = @transformer.call parsed
      result['mappings'].should == {'a' => 'a'}
      result['source'].should   == 'test'
    end

    it "(import a as b, c from 'test')" do
      parsed = Gene::Parser.parse(example.description)
      result = @transformer.call parsed
      result['mappings'].should == {'a' => 'b', 'c' => 'c'}
      result['source'].should   == 'test'
    end
  end
end