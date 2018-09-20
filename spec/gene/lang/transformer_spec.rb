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
      result[Gene::Lang::Transformer::NORMALIZED].should == true
      result['mappings'].should == {'a' => 'a'}
      result['source'].should   == 'test'
    end

    it "(import a as b, c from 'test')" do
      parsed = Gene::Parser.parse(example.description)
      result = @transformer.call parsed
      result[Gene::Lang::Transformer::NORMALIZED].should == true
      result['mappings'].should == {'a' => 'b', 'c' => 'c'}
      result['source'].should   == 'test'
    end

    it "(import a/b from 'test')" do
      parsed = Gene::Parser.parse(example.description)
      result = @transformer.call parsed
      result[Gene::Lang::Transformer::NORMALIZED].should == true
      result['mappings'].should == {'a/b' => 'b'}
      result['source'].should   == 'test'
    end

    it "(import a as b, c from 'test' of 'pkg')" do
      pending
      parsed = Gene::Parser.parse(example.description)
      result = @transformer.call parsed
      result[Gene::Lang::Transformer::NORMALIZED].should == true
      result['mappings'].should == {'a' => 'b', 'c' => 'c'}
      result['source'].should   == 'test'
      result['package'].should  == 'pkg'
    end
  end

  describe "try" do
    it "
      (try
        1
        2
      catch SomeException
        (e => 'We got some error')
      catch GenericException
        (e => 'We got error')
      )
    " do
      pending
      parsed = Gene::Parser.parse(example.description)
      result = @transformer.call parsed
      result[Gene::Lang::Transformer::NORMALIZED].should == true
      result['body'].should is_a Gene::Lang::Statements
    end
  end
end