require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "Jit" do
  it "should work" do
    app = Application.new [
      [WRITE, 'a', 1],
      [READ, 'a'],
      [APP_END],
    ]
    app.run.should == 1
  end
end
