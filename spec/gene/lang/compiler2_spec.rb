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

  testcases = {
    ' # Compiles empty code to below output
      # !with-root-context!
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # assert
      # !throw-error!
      (assert false)
    ' =>
    <<-JAVASCRIPT,
      Gene.assert(false);
    JAVASCRIPT

    ' # Variables
      a
    ' =>
    <<-JAVASCRIPT,
      $context.get_member("a");
    JAVASCRIPT

    ' # Variables
      (1 == 1)
    ' =>
    <<-JAVASCRIPT,
      (1 == 1);
    JAVASCRIPT

    ' # Variables
      (var a 1)
    ' =>
    <<-JAVASCRIPT,
      $context.var("a", 1);
    JAVASCRIPT

    ' # Variables
      (a ++)
    ' =>
    <<-JAVASCRIPT,
      $context.set_member("a", ($context.get_member("a") + 1));
    JAVASCRIPT

    ' # Variables
      (fnxx
        (return 1)
        2
      )
    ' =>
    <<-JAVASCRIPT,
      $context.fn("", [], function($context) {
        try {
          var $result;
          (($result = 1), Gene.throw("#return"));
          ($result = 2);
          return $result;
        } catch (error) {
          if ((error == "#return")) {
            return $result;
          } else {
            throw error;
          }
        }
      });
    JAVASCRIPT

    ' # Function
      (fn f [a b]
        (a + b)
      )
    ' =>
    <<-JAVASCRIPT,
      $context.fn("f", ["a", "b"], function($context) {
        var $result;
        ($result = ($context.get_member("a") + $context.get_member("b")));
        return $result;
      });
    JAVASCRIPT

    ' # Function call
      (f 1 2)
    ' =>
    <<-JAVASCRIPT,
      $context.get_member("f").invoke(1, 2);
    JAVASCRIPT

    ' # Anonymous function
      (fnx [a b])
    ' =>
    <<-JAVASCRIPT,
      $context.fn("", ["a", "b"], function($context) {
        var $result;
        return $result;
      });
    JAVASCRIPT

    ' # Dummy function
      (fnxx)
    ' =>
    <<-JAVASCRIPT,
      $context.fn("", [], function($context) {
        var $result;
        return $result;
      });
    JAVASCRIPT

    ' # If
      (if true 1 2 else 3 4)
    ' =>
    <<-JAVASCRIPT,
      (true ? (1, 2) : (3, 4));
    JAVASCRIPT

    ' # For
      (for (var i 0) (i < 10) true
        1
        2
      )
    ' =>
    <<-JAVASCRIPT,
      (function() {
        for ($context.var("i", 0); ($context.get_member("i") < 10); true) {
          1;
          2;
        }
      })();
    JAVASCRIPT

    ' # Multiple statements with root context
      # !with-root-context!
      # !throw-error!
      (var a 1)
      (assert ((a + 1) == 3))
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        $context.var("a", 1);
        ($result = Gene.assert((($context.get_member("a") + 1) == 3)));
        return $result;
      })($root_context);
    JAVASCRIPT

  }

  focus = testcases.keys.find {|key| key.include? '!focus!' }
  if focus
    puts "\nRun focused tests only!\n"
  end

  testcases.each do |input, result|
    next if focus and not input.include? '!focus!'

    it input do
      pending if input.index('!pending!') and not input.include? '!focus!'

      parsed = Gene::Parser.parse(input)
      @application.global_namespace.set_member('$parsed_code', parsed)

      code =
        if input.include?('!with-root-context!')
          '(compile ^^with_root_context $parsed_code)'
        else
          '(compile $parsed_code)'
        end

      output = @application.parse_and_process(code)
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
