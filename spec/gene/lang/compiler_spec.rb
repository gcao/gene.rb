require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Compiler do
  before do
    @compiler = Gene::Lang::Compiler.new
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

    '
      (var a)
      (var b)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $context.var_("a");
        $result = $context.var_("b");
        return $result;
      })($root_context);
    JAVASCRIPT

    '
      # !eval-to-true!
      (var result 0)
      (for (var i 0)(i < 5)(i += 1)
        (result += i)
      )
      (result == 10)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $context.var_("result", 0);
        for($context.var_("i", 0); ($context.get_member("i") < 5); $context.set_member("i", ($context.get_member("i") + 1))) {
          $context.set_member("result", ($context.get_member("result") + $context.get_member("i")));
        };
        $result = ($context.get_member("result") == 10);
        return $result;
      })($root_context);
    JAVASCRIPT

    '
      (var result 0)
      (for (var i 0)(i < 100)(i += 1)
        (if (result >= 100)
          (break)
        else
          (result += i)
        )
      )
      (result == 105)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $context.var_("result", 0);
        for($context.var_("i", 0); ($context.get_member("i") < 100); $context.set_member("i", ($context.get_member("i") + 1))) {
          if (($context.get_member("result") >= 100)) {
            break;
          } else {
            $context.set_member("result", ($context.get_member("result") + $context.get_member("i")));
          };
        };
        $result = ($context.get_member("result") == 105);
        return $result;
      })($root_context);
    JAVASCRIPT

    '
      # !pending!
      # !eval-to-true!
      (fn f [a b]
        (a + b)
      )
      ((f 1 2) == 3)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $context.set_member("f", new Gene.Func("f", ["a", "b"], function(options){
          var $result;
          var scope = new Gene.Scope(this.parent_scope, this.inherit_scope);
          var new_context = options.context.extend({scope: scope});
          $result = (new_context.get_member("a") + new_context.get_member("b"));
          return $result;
        }));
        $result = ($context.get_member("f").invoke({context: $context, arguments: [1, 2]}) == 3);
        return $result;
      })($root_context);
    JAVASCRIPT

    '
      (f 1 2)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        $result = $context.get_member("f").invoke({context: $context, arguments: [1, 2]});
        return $result;
      })($root_context);
    JAVASCRIPT

    '
      # !pending!
      (class A
        (method test [a b]
          (a + b)
        )
      )
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context){
        var $result;
        return $result;
      })($root_context);
    JAVASCRIPT

  }.each do |input, result|
    it input do
      pending if input.index('!pending!')

      output = @compiler.parse_and_process(input)
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