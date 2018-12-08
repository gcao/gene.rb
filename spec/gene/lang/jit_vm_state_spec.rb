require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "JIT VM State" do
  before do
    @compiler = Compiler.new
    APP.reset
  end

  it "
    # Should work
    (gene_save_vm_state '/tmp/gene_vm_state.json')
    1
  " do
    mod = @compiler.parse_and_compile example.description
    APP.run(mod).should == 1
    state = VmState.from_file '/tmp/gene_vm_state.json'
    state.resume.should == 1
  end

end
