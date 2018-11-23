require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

include Gene::Lang::Jit

describe "!!! DEBUGGING ONLY !!!" do
  before do
    @compiler = Compiler.new
  end

    # Copied from jit_spec.rb
    it "
      # loop...(fn...break) should work
      (loop ((fnxx (break))))
      1
    " do
      mod = @compiler.parse_and_compile example.description
      app = Application.new(mod)
      app.run.should == 1
    end
end