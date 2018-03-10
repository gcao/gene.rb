require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Parser" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs

    dir  = "#{File.dirname(__FILE__)}/../../lib/gene/lang"
    file = "#{dir}/parser.gene"
    @application.parse_and_process File.read(file), dir: dir, file: file
  end


  %Q~
    (var result ((new Parser '') .parse))
    (assert (result .is Stream))

    (var result ((new Parser '1 2') .parse))
    (assert (result .is Stream))

    (var result ((new Parser '1') .parse))
    (assert (result == 1))

    (var result ((new Parser '-1') .parse))
    (assert (result == -1))

    (var result ((new Parser '1.5') .parse))
    (assert (result == 1.5))

    (var result ((new Parser 'true') .parse))
    (assert (result == true))

    (var result ((new Parser 'false') .parse))
    (assert (result == false))

    (var result ((new Parser 'null') .parse))
    (assert (result == null))

    (var result ((new Parser 'undefined') .parse))
    (assert (result == undefined))

    (var result ((new Parser 'a') .parse))
    (assert (result == :a))

    (var result ((new Parser '\\\\#') .parse))
    (assert (result == :#))

    (var result ((new Parser '"a"') .parse))
    (assert (result == 'a'))

    (var result ((new Parser '"a \nmultiline \nstring"') .parse))
    (assert (result == 'a \nmultiline \nstring'))

    (var result ((new Parser '[]') .parse))
    (assert (result == []))

    (var result ((new Parser '[1]') .parse))
    (assert (result == [1]))

    (var result ((new Parser '[# 1\n]') .parse))
    (assert (result == []))

    (var result ((new Parser '()') .parse))
    (assert (result == noop))

    (var result ((new Parser '(a 1)') .parse))
    (assert ((result .type) == :a))
    (assert ((result .data) == [1]))

    (var result ((new Parser '{^a b}') .parse))
    (assert (result == {^a :b}))

    (var result ((new Parser '{^^a}') .parse))
    (assert (result == {^^a}))

    (var result ((new Parser '{^+a}') .parse))
    (assert (result == {^^a}))

    (var result ((new Parser '{^!a}') .parse))
    (assert (result == {^!a}))

    (var result ((new Parser '{^-a}') .parse))
    (assert (result == {^!a}))

    (var result ((new Parser '(a ^name "value" 1)') .parse))
    (assert ((result .type) == :a))
    (assert ((result .get 'name') == 'value'))
    (assert ((result .data) == [1]))

    (var result ((new Parser '[1 {^a b}]') .parse))
    (assert (result == [1 {^a :b}]))

    (var result ((new Parser '{^a [1 2]}') .parse))
    (assert (result == {^a [1 2]}))

    (var result ((new Parser '(a ^b [1 2] ^c {^d e} 3)') .parse))
    (assert ((result .type) == :a))
    (assert ((result .get 'b') == [1 2]))
    (assert ((result .get 'c') == {^d :e}))
    (assert ((result .data) == [3]))
  ~.split("\n\n").each do |code|
    it code do
      input = example.description
      pending if input.index('!pending!')

      @application.parse_and_process(input)
    end
  end
end