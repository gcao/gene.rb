require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Compiler do
  before do
    @compiler = Gene::Lang::Compiler.new
  end

  {
    '(var a)'         => 'var a;',
  }.each do |input, result|
    it "compile #{input} should work" do
      output = @compiler.parse_and_process(input)
      s1 = output.gsub /^\s+/, ''
      s2 = result.gsub /^\s+/, ''
      s1.should == s2
    end
  end
end
