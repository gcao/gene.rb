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

    ' # Return
      (return 1)
    ' =>
    <<-JAVASCRIPT,
      Gene.return(1);
    JAVASCRIPT

    ' # Throw
      (throw 1)
    ' =>
    <<-JAVASCRIPT,
      Gene.throw(1);
    JAVASCRIPT

    ' # Variables
      (a ++)
    ' =>
    <<-JAVASCRIPT,
      $context.set_member("a", ($context.get_member("a") + 1));
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

    ' # Function + Return
      (fnxx
        (return 1)
        2
      )
    ' =>
    <<-JAVASCRIPT,
      $context.fn("", [], function($context) {
        try {
          var $result;
          Gene.return(1);
          ($result = 2);
          return $result;
        } catch (error) {
          if ((error instanceof Gene.Return)) {
            return error.value;
          } else {
            throw error;
          }
        }
      });
    JAVASCRIPT

    ' # Function call
      (f 1 2)
    ' =>
    <<-JAVASCRIPT,
      $context.get_member(\"f\").invoke($context, undefined, Gene.Base.from_data([1, 2]));
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
      (if true 1 2)
    ' =>
    <<-JAVASCRIPT,
      (true ? (1, 2) : undefined);
    JAVASCRIPT

    ' # If...else
      (if true 1 2 else 3 4)
    ' =>
    <<-JAVASCRIPT,
      (true ? (1, 2) : (3, 4));
    JAVASCRIPT

    ' # If...else_if...else
      (if true 1 2 else_if true 3 4 else 5 6)
    ' =>
    <<-JAVASCRIPT,
      (true ? (1, 2) : (true ? (3, 4) : (5, 6)));
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

    ' # Loop
      (loop
        1
        2
      )
    ' =>
    <<-JAVASCRIPT,
      (function() {
        while (true) {
          1;
          2;
        }
      })();
    JAVASCRIPT

    ' # Complex
      # !with-root-context!
      # !eval!
      (var a 1)
      (assert ((a + 1) == 2))
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        $context.var("a", 1);
        ($result = Gene.assert((($context.get_member("a") + 1) == 2)));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Complex
      # !with-root-context!
      # !eval!
      (fn f [a b]
        (a + b)
      )
      (assert ((f 1 2) == 3))
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        $context.fn("f", ["a", "b"], function($context) {
          var $result;
          ($result = ($context.get_member("a") + $context.get_member("b")));
          return $result;
        });
        ($result = Gene.assert(($context.get_member("f").invoke($context, undefined, Gene.Base.from_data([1, 2])) == 3)));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Complex
      # !with-root-context!
      # !eval!
      (var a 1)
      (fn f b
        (var c 3)
        ((a + b) + c)
      )
      (assert ((f 2) == 6))
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        $context.var("a", 1);
        $context.fn("f", ["b"], function($context) {
          var $result;
          $context.var("c", 3);
          ($result = (($context.get_member("a") + $context.get_member("b")) + $context.get_member("c")));
          return $result;
        });
        ($result = Gene.assert(($context.get_member("f").invoke($context, undefined, Gene.Base.from_data([2])) == 6)));
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

      if focus and ENV["save"]
        File.write File.expand_path(File.dirname(__FILE__) + '/../../../gene-js/build/src/generated.js'), result
      end

      if input.index('!throw-error!')
        lambda {
          @ctx.eval(output)
        }.should raise_error
      elsif input.index('!eval!')
        @ctx.eval(output)
      end
    end
  end
end
