require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# Remove leading/trailing spaces, new-lines
def compress code
  code.gsub(/(^\s*)|(\s*\n\s*)|(\s*$)/, '')
end

describe Gene::Lang::Compiler do
  before do
    @compiler = Gene::Lang::Compiler.new
  end

  {
    '
      (var a)
    ' => '
      Gene.var_("a")(new Gene.Context());
    ', '
      # pending
      (var result 0)
      (for (var i 0)(i < 5)(i += 1)
        (result += i)
      )
      (assert (result == 10))
    ' => '
      var context = new Gene.Context();
      Gene.for(
        Gene.var_("i",0),
        Gene.binary("<",gene.get_member("i"),5),
        Gene.binary("+=",gene.get_member("i"),1),
        [
          Gene.binary("+=","result","1")
        ]
      )(context);
    ',
  }.each do |input, result|
    it "compile #{input} should work" do
      pending if input =~ /^\s*# pending/

      output = @compiler.parse_and_process(input)
      s1 = compress(output)
      s2 = compress(result)
      s1.should == s2
    end
  end
end
