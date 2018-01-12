require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "JavaScript representation in Gene" do
  before do
  end

  {
    ' # Create new instance
      # !pending!
      (js-new A)
    ' =>
    <<-JAVASCRIPT,
      new A()
    JAVASCRIPT

    ' # Define variable
      # !pending!
      (js-var a 1)
    ' =>
    <<-JAVASCRIPT,
      var a = 1;
    JAVASCRIPT

    ' # Define function
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      function f(a, b) {
      }
    JAVASCRIPT

    ' # if
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      if (true) {
        1;
      }
    JAVASCRIPT

    ' # if...else
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      if (true) {
        1;
      } else {
        2;
      }
    JAVASCRIPT

    ' # if...else if...else
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      if (true) {
        1;
      } else if (true) {
        2;
      } else {
        3;
      }
    JAVASCRIPT

    ' # for
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      for (var a = 0; a < 100; a ++) {
        1;
      }
    JAVASCRIPT

    ' # binary expressions
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      a + b
    JAVASCRIPT

    ' # unary expressions
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      !a
    JAVASCRIPT

    ' # return
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      return 1;
    JAVASCRIPT

    ' # Object
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      {
        "a" : 1,
        "b" : 2
      }
    JAVASCRIPT

    ' # Object access
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      a[1]
    JAVASCRIPT

    ' # Invoke function
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      f(a, b)
    JAVASCRIPT

    ' # Complex expression
      # !pending!
    ' =>
    <<-JAVASCRIPT,
      var a = new A()[0](1, 2);
    JAVASCRIPT

  }.each do |input, result|
    it input do
      pending if input.index('!pending!')

      parsed = Gene::Parser.parse(input)
      @application.global_namespace.set_member('$parsed_code', parsed)

      output = @application.parse_and_process('(compile $parsed_code)')
      compare_code output, result
    end
  end
end