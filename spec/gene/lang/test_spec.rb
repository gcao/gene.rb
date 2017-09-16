require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Gene::Lang::Interpreter do
  before do
    @application = Gene::Lang::Application.new
    @interpreter = Gene::Lang::Interpreter.new @application.root_context
    pending
    @interpreter.parse_and_process File.read(File.dirname(__FILE__) + '/../../../lib/gene/lang/test.glang')
  end

  it "()" do
    result = @interpreter.parse_and_process(example.description)
  end
end