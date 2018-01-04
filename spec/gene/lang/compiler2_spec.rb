require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Compiler do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
    @application.load File.expand_path(File.dirname(__FILE__) + '/../../../lib/gene/lang/compiler.gene')
    @ctx = V8::Context.new
    @ctx.eval File.read "gene-js/build/src/index.js"
  end

  {
    '
      # !eval-to-true!
      (var a 1)
      (a == 1)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $context.var_("a", 1);
        $result = ($context.get_member("a") == 1);
        return $result;
      })($root_context);
    JAVASCRIPT

  }.each do |input, result|
    it input do
      pending if input.index('!pending!')

      parsed = Gene::Parser.parse(input)
      @application.global_namespace.set_member('$parsed_code', parsed)

      output = @application.parse_and_process('((new Compiler) .compile $parsed_code)')
      compare_code output, result

      if input.index('!eval-to-true!')
        result = @ctx.eval(output)
        if not result
          print_code output
        end
        result.should be_true
      end
    end
  end
end
