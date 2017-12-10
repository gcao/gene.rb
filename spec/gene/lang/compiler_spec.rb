require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'v8'

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
      (var a 1)
    ' => '
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $result = $context.var_("a", 1);
        return $result;
      })($root_context);
    ',
    '
      (var a)
      (var b)
    ' => '
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $context.var_("a");
        $result = $context.var_("b");
        return $result;
      })($root_context);
    ',
    '
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
    it "#{'-' * 50}#{input}" do
      pending if input =~ /^\s*# pending/

      output = @compiler.parse_and_process(input)
      s1 = compress(output)
      s2 = compress(result)
      s1.should == s2
    end
  end
end

describe Gene::Lang::Compiler do
  before do
    @compiler = Gene::Lang::Compiler.new
    @ctx = V8::Context.new
    @ctx.eval File.read "gene-js/build/src/index.js"
  end

  it '
    (var a 1)
    (var b 2)
    (a + b)
  ' do
    output = @compiler.parse_and_process(example.description)
    puts
    puts output.gsub(/^\s*/, '')
    @ctx.eval(output).should == 3
  end
end