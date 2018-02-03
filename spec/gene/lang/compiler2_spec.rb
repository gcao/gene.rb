require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Compiler do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
    @application.load File.expand_path(File.dirname(__FILE__) + '/../../../lib/gene/lang/gene2js.gene')
    @application.load File.expand_path(File.dirname(__FILE__) + '/../../../lib/gene/lang/compiler.gene')

    @ctx = V8::Context.new
    @ctx.eval File.read "gene-js/build/src/index.js"
  end

  {
    ' # Compiles empty code to below output
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # assert
      # !focus!
      # !throw-error!
      (assert false)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = Gene.assert(false));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Variables
      (var a 1)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = $context.var_("a", 1));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Variables
      # !pending!
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
    next if ENV['focus'] and not input.include? '!focus!'

    it input do
      pending if input.index('!pending!') and not input.include? '!focus!'

      parsed = Gene::Parser.parse(input)
      @application.global_namespace.set_member('$parsed_code', parsed)

      output = @application.parse_and_process('(compile $parsed_code)')
      compare_code output, result

      if input.index('!throw-error!')
        lambda {
          @ctx.eval(output)
        }.should raise_error
      elsif input.index('!eval-to-true!')
        result = @ctx.eval(output)
        if not result
          print_code output
        end
        result.should be_true
      end
    end
  end
end
