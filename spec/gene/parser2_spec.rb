require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Parser" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs

    dir  = "#{File.dirname(__FILE__)}/../../lib/gene/lang"
    file = "#{dir}/parser.gene"
    @application.parse_and_process File.read(file), dir: dir, file: file
  end


  %q~
    (var result ((new Parser '') .parse))
    (assert (result .is Stream))

    (var result ((new Parser '1') .parse))
    (assert (result == 1))

    (var result ((new Parser 'true') .parse))
    (assert (result == true))

    (var result ((new Parser 'a') .parse))
    (assert (result == :a))

    (var result ((new Parser '"a"') .parse))
    (assert (result == 'a'))

    (var result ((new Parser '[]') .parse))
    (assert (result == []))

    (var result ((new Parser '[1]') .parse))
    (assert (result == [1]))

    (var result ((new Parser '()') .parse))
    (assert (result == noop))

    (var result ((new Parser '(a 1)') .parse))
    (assert ((result .type) == :a))
    (assert ((result .data) == [1]))

  ~.split("\n\n").each do |code|
    it code do
      input = example.description
      pending if input.index('!pending!')

      @application.parse_and_process(input)
    end
  end
end