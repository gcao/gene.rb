require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "JavaScript representation in Gene" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
    @application.load File.expand_path(File.dirname(__FILE__) + '/../../../lib/gene/lang/gene2js.gene')
    @application.parse_and_process <<-GENE
      (fn compress code
        ^^global
        ($invoke ('' code) 'gsub' #/(^\\s*)|(\\s*\\n\\s*)|(\\s*$)/ '')
      )
      (fn compile_and_verify [first second]
        ^^global
        ^!eval_arguments
        (first = (gene2js first))
        (if_not ((compress first) == (compress second))
          (println first)
          (throw
            ('' first " does not equal " second)
          )
        )
      )
    GENE
  end

  %q~
    # Atomic expression / statements
    (compile_and_verify
      "abc"
      '
        "abc";
      '
    )

    (compile_and_verify
      null
      '
        null;
      '
    )

    (compile_and_verify
      undefined
      '
      '
    )

    (compile_and_verify
      ^^#render_args
      (%symbol 'undefined')
      '
        undefined;
      '
    )

    (compile_and_verify
      true
      '
        true;
      '
    )

    (compile_and_verify
      1
      '
        1;
      '
    )

    (compile_and_verify
      [a b]
      '
        [a, b];
      '
    )

    (compile_and_verify
      {
        ^a 1
        ^b test
      }
      '
        {
          "a": 1,
          "b": test
        }
      '
    )

    (compile_and_verify
      (var a)
      '
        var a;
      '
    )

    (compile_and_verify
      (var a 1)
      '
        var a = 1;
      '
    )

    (compile_and_verify
      (a . b)
      '
        a.b;
      '
    )

    (compile_and_verify
      (a .b)
      '
        a.b;
      '
    )

    (compile_and_verify
      (a <- b c)
      '
        a(b, c);
      '
    )

    (compile_and_verify
      (a <- false)
      '
        a(false);
      '
    )

    (compile_and_verify
      (a \~ b \~ c)
      '
        (a, b, c);
      '
    )

    (compile_and_verify
      (fn f [a b] 1)
      '
        function f(a, b) {
          1;
        }
      '
    )

    (compile_and_verify
      (fnx [a b] 1)
      '
        function(a, b) {
          1;
        }
      '
    )

    (compile_and_verify
      (fnxx 1 2)
      '
        function() {
          1;
          2;
        }
      '
    )

    (compile_and_verify
      (new A a b)
      '
        new A(a, b);
      '
    )

    (compile_and_verify
      (a @ 1)
      '
        a[1];
      '
    )

    (compile_and_verify
      (a @ 'name')
      '
        a["name"];
      '
    )

    (compile_and_verify
      (a + b)
      '
        (a + b);
      '
    )

    (compile_and_verify
      (a ++)
      '
        (a ++);
      '
    )

    (compile_and_verify
      (! a)
      '
        ! a;
      '
    )

    (compile_and_verify
      (return a)
      '
        return a;
      '
    )

    (compile_and_verify
      (throw a)
      '
        throw a;
      '
    )

    (compile_and_verify
      (try
        1
        2
      catch error
        3
        4
      finally
        5
        6
      )
      '
        try {
          1;
          2;
        } catch (error) {
          3;
          4;
        } finally {
          5;
          6;
        }
      '
    )

    (compile_and_verify
      (if a 1 2)
      '
        if (a) {
          1;
          2;
        }
      '
    )

    (compile_and_verify
      (a ? 1 2)
      '
        (a ? 1 : 2);
      '
    )

    (compile_and_verify
      (if a
        1
        2
      else_if b
        3
        4
      else
        5
        6
      )
      '
        if (a) {
          1;
          2;
        } else if (b) {
          3;
          4;
        } else {
          5;
          6;
        }
      '
    )

    (compile_and_verify
      (for (var i 0) (i < 5) (i ++)
        1
        2
      )
      '
        for (var i = 0; (i < 5); (i ++)) {
          1;
          2;
        }
      '
    )

    (compile_and_verify
      (for i in list
        1
        2
      )
      '
        for (var i in list) {
          1;
          2;
        }
      '
    )

    # More complex code
    (compile_and_verify
      (var a (((new A) @ 0) <- 1 2))
      '
        var a = new A()[0](1, 2);
      '
    )

    (compile_and_verify
      ((Gene .assert) <- false )
      '
        Gene.assert(false);
      '
    )

    (compile_and_verify
      (fnxx (var $root_context ($application . (create_root_context <-))) ((fnx $context (var $result) ($result = ((Gene .assert) <- false)) (return $result)) <- $root_context))
      '
        function() {
          var $root_context = $application.create_root_context();
          (function($context) {
            var $result;
            ($result = Gene.assert(false));
            return $result;
          })($root_context);
        }
      '
    )

  ~.split("\n\n").each do |code|
    next if code =~ /^\s+$/

    it code do
      input = example.description
      pending if input.index('!pending!')

      @application.parse_and_process(input)
    end
  end
end