require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "JavaScript representation in Gene" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
    @application.load File.expand_path(File.dirname(__FILE__) + '/../../../lib/gene/lang/compiler.gene')
    @application.parse_and_process <<-GENE
      (fn js code
        ^^global
        ^!eval_arguments
        (compile code)
      )
      (fn compress code
        ^^global
        ($invoke ('' code) 'gsub' #/(^\\s*)|(\\s*\\n\\s*)|(\\s*$)/ '')
      )
      (fn compare [first second]
        ^^global
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
    (compare
      (js
        (var a 1)
      )
      '
        var a = 1;
      '
    )

    (compare
      (js
        (fn f [a b] 1)
      )
      '
        function f(a, b) {
          1;
        }
      '
    )

    (compare
      (js
        (fnx [a b] 1)
      )
      '
        function(a, b) {
          1;
        }
      '
    )

    (compare
      (js
        (new A a b)
      )
      '
        new A(a, b);
      '
    )

    (compare
      (js
        (a @ 1)
      )
      '
        a[1];
      '
    )

    (compare
      (js
        (a + b)
      )
      '
        (a + b);
      '
    )

    (compare
      (js
        (! a)
      )
      '
        ! a;
      '
    )

    (compare
      (js
        (return a)
      )
      '
        return a;
      '
    )

    (compare
      (js
        (if a 1 2)
      )
      '
        if (a) {
          1;
          2;
        }
      '
    )

    (compare
      (js
        (a ? 1 2)
      )
      '
        (a ? 1 : 2);
      '
    )

    (compare
      (js
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

    (compare
      (js
        (for (var i 0) (i < 5) (i ++)
          1
          2
        )
      )
      '
        for (var i = 0; (i < 5); (i ++)) {
          1;
          2;
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

  # {
  #   # Atomic operations
  #   ' # dummy function
  #     # !pending!
  #     (jfnxx 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     function() {
  #       1;
  #     }
  #   JAVASCRIPT

  #   ' # dot access
  #     # !pending!
  #     (jdot a b c)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     a.b.c
  #   JAVASCRIPT

  #   ' # ()
  #     # !pending!
  #     (jgrp a b)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     (a, b)
  #   JAVASCRIPT

  #   ' # for
  #     # !pending!
  #     (jfor (jvar a 0) (jbin a < 100) (jbin a += 1) 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     for (var a = 0; a < 100; a += 1) {
  #       1;
  #     }
  #   JAVASCRIPT

  #   ' # Object
  #     # !pending!
  #     {
  #       ^a 1
  #       ^b 2
  #     }
  #   ' =>
  #   <<-JAVASCRIPT,
  #     {
  #       "a" : 1,
  #       "b" : 2
  #     }
  #   JAVASCRIPT

  #   ' # Invoke function
  #     # !pending!
  #     (jcall f a b)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     f(a, b)
  #   JAVASCRIPT

  #   # Building blocks built on top of atomic components, that are commonly used

  #   # Programs
  #   '
  #     # !pending!
  #     (jvar a (jcall (jget (jnew A) 0) 1 2))
  #   ' =>
  #   <<-JAVASCRIPT,
  #     var a = new A()[0](1, 2);
  #   JAVASCRIPT

  # }.each do |input, result|
  #   it input do
  #     pending if input.index('!pending!')

  #     parsed = Gene::Parser.parse(input)
  #     @application.global_namespace.set_member('$parsed_code', parsed)

  #     output = @application.parse_and_process('(compile $parsed_code)')
  #     compare_code output, result
  #   end
  # end
end