require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Compiler do
  before do
    @compiler = Gene::Lang::Compiler.new
  end

  {
    '
      (var a 1)
    ' => <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $result = $context.var_("a", 1);
        return $result;
      })($root_context);
    JAVASCRIPT

    '
      (var a)
      (var b)
    ' => <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $context.var_("a");
        $result = $context.var_("b");
        return $result;
      })($root_context);
    JAVASCRIPT

    '
      # pending
      (var result 0)
      (for (var i 0)(i < 5)(i += 1)
        (result += i)
      )
      (assert (result == 10))
    ' => <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      var context = new Gene.Context();
      Gene.for(
        Gene.var_("i",0),
        Gene.binary("<",gene.get_member("i"),5),
        Gene.binary("+=",gene.get_member("i"),1),
        [
          Gene.binary("+=","result","1")
        ]
      )(context);
    JAVASCRIPT
  }.each do |input, result|
    it "#{'-' * 50}#{input}" do
      pending if input =~ /^\s*# pending/

      output = @compiler.parse_and_process(input)
      compare_code result, output
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
    # puts
    # puts output.to_s.gsub(/^\s*/, '')
    @ctx.eval(output).should == 3
  end
end