require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Parser" do
  before do
    @application = Gene::Lang::Application.new
    @application.load_core_libs

    dir  = "#{File.dirname(__FILE__)}/../../lib/gene/lang"
    file = "#{dir}/parser.gene"
    @application.parse_and_process File.read(file), dir: dir, file: file
  end

  it "
    (var result ((new Parser '1') .parse))
    (assert (result == 1))
  " do
    input = example.description
    pending if input.index('!pending!')

    @application.parse_and_process(input)
  end
end