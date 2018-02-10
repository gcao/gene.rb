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

  # In order to make "if", "for" etc to return result (everything is expression)
  # Change last statement of if/for block to "$result = <last expression>;"
  # Change break statement to "$result = <arg passed to break>; break;"

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
        ($result = $context.var("a", 1));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Variables
      # !eval-to-true!
      (var a 1)
      (a == 1)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        $context.var("a", 1);
        ($result = ($context.get_member("a") == 1));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Variables
      (a + b)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = ($context.get_member("a") + $context.get_member("b")));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Variables
      # !focus!
      (a ++)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = $context.set_member("a", ($context.get_member("a") + 1)));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Variables
      # !pending!
      (fnxx
        (return 1)
        2
      )
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = function() {
          try {
            var $result;
            ($result = 1);
            Gene.throw("#return");
            ($result = 2);
            return $result;
          } catch (error) {
            if (error == "#return") {
              return $result;
            } else {
              throw error;
            }
          }
        });
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Function
      (fn f [a b]
        (a + b)
      )
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = $context.fn("f", ["a", "b"], function($context) {
          var $result;
          ($result = ($context.get_member("a") + $context.get_member("b")));
          return $result;
        }));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Function call
      (f 1 2)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = $context.get_member("f").invoke(1, 2));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Anonymous function
      # !pending!
      (fnx [a b])
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = $context.fnx(["a", "b"], function($context) {
          var $result;
          return $result;
        }));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # Dummy function
      # !pending!
      (fnxx)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = $context.fnxx(function($context) {
          var $result;
          return $result;
        }));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # If
      (if true 1 2 else 3 4)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = (true ? (1, 2) : (3, 4)));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # If
      ((if true 1 else 2) + 3)
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = ((true ? 1 : 2) + 3));
        return $result;
      })($root_context);
    JAVASCRIPT

    ' # For
      (for (var i 0) (i < 10) true
        1
        2
      )
    ' =>
    <<-JAVASCRIPT,
      var $root_context = $application.create_root_context();
      (function($context) {
        var $result;
        ($result = (function() {
          for ($context.var("i", 0); ($context.get_member("i") < 10); true) {
            1;
            2;
          }
        })());
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
