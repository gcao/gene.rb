require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "JavaScript representation in Gene" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs
    @application.load File.expand_path(File.dirname(__FILE__) + '/../../../lib/gene/lang/compiler.gene')
    @application.parse_and_process <<-GENE
      (fn compress code
        ^^global
        ($invoke ('' code) 'gsub' #/(^\\s*)|(\\s*\\n\\s*)|(\\s*$)/ '')
      )
      (fn compare [first second]
        ^^global
        (if_not ((compress first) == (compress second))
          (throw
            ('' first " does not equal " second)
          )
        )
      )
    GENE
  end

  %q~
    # !pending!
    (compare
      (compile
        (:var a 1)
      )
      '
        var a = 1;
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
  #   ' # var
  #     # !pending!
  #     (jvar a 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     var a = 1;
  #   JAVASCRIPT

  #   ' # function
  #     # !pending!
  #     (jfn f [a b] 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     function f(a, b) {
  #       1;
  #     }
  #   JAVASCRIPT

  #   ' # anonymous function
  #     # !pending!
  #     (jfnx [a b] 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     function(a, b) {
  #       1;
  #     }
  #   JAVASCRIPT

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

  #   ' # new
  #     # !pending!
  #     (jnew A 1 2)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     new A(1, 2)
  #   JAVASCRIPT

  #   ' # binary expressions
  #     # !pending!
  #     (jbin a + b)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     a + b
  #   JAVASCRIPT

  #   ' # unary expressions
  #     # !pending!
  #     (jpre ! a)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     !a
  #   JAVASCRIPT

  #   ' # return
  #     # !pending!
  #     (jret 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     return 1;
  #   JAVASCRIPT

  #   ' # ()
  #     # !pending!
  #     (jgrp a b)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     (a, b)
  #   JAVASCRIPT

  #   ' # if
  #     # !pending!
  #     (jif true 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     if (true) {
  #       1;
  #     }
  #   JAVASCRIPT

  #   ' # if...else
  #     # !pending!
  #     (jif true 1 else 2)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     if (true) {
  #       1;
  #     } else {
  #       2;
  #     }
  #   JAVASCRIPT

  #   ' # if...else if...else
  #     # !pending!
  #     (jif true 1 else_if true 2 else 3)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     if (true) {
  #       1;
  #     } else if (true) {
  #       2;
  #     } else {
  #       3;
  #     }
  #   JAVASCRIPT

  #   ' # for
  #     # !pending!
  #     (jfor (jvar a 0) (jbin a < 100) (jbin a ++) 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     for (var a = 0; a < 100; a ++) {
  #       1;
  #     }
  #   JAVASCRIPT

  #   ' # for...in
  #     # !pending!
  #     (jfor a in b [])
  #   ' =>
  #   <<-JAVASCRIPT,
  #     for (var a in b) {
  #       1;
  #     }
  #   JAVASCRIPT

  #   ' # Ternary expression:  a ? b : c
  #     # !pending!
  #     (jtern true ? 1 2)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     true ? 1 : 2
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

  #   ' # Object access
  #     # !pending!
  #     (jget a 1)
  #   ' =>
  #   <<-JAVASCRIPT,
  #     a[1]
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