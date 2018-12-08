require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Gene::Lang::Jit

describe "JIT VM State" do
  before do
    @compiler = Compiler.new
    APP.reset
  end

  it "
    # gene_save_vm_state saves vm state and continues to run
    (gene_save_vm_state '/tmp/gene_vm_state.json')
    1
  " do
    mod = @compiler.parse_and_compile example.description
    APP.run(mod).should == 1
    state = VmState.from_file '/tmp/gene_vm_state.json'
    state.resume.should == 1
  end

  it "
    # gene_save_and_exit saves vm state and exits with 0 (success) or another value(failure)
    (gene_save_and_exit '/tmp/gene_vm_state.json')
    1
  " do
    mod = @compiler.parse_and_compile example.description
    APP.run(mod).should == 0
    state = VmState.from_file '/tmp/gene_vm_state.json'
    state.resume.should == 1
  end

  it "
    # gene_save_and_exit works inside loop
    # It'll be invoked multiple times
    (var sum 0)
    (for (var i 1) (i < 4) (i += 1)
      (sum = (sum + i))
      (gene_save_and_exit '/tmp/gene_vm_state.json')
    )
    sum
  " do
    mod = @compiler.parse_and_compile example.description
    APP.run(mod).should == 0
    state = VmState.from_file '/tmp/gene_vm_state.json'
    state.resume.should == 0
    state = VmState.from_file '/tmp/gene_vm_state.json'
    state.resume.should == 0
    state = VmState.from_file '/tmp/gene_vm_state.json'
    state.resume.should == 6
  end

  it "
    # gene_save_and_exit works inside function
    (fn f a
      (gene_save_and_exit '/tmp/gene_vm_state.json')
      a
    )
    (f 1)
  " do
    mod = @compiler.parse_and_compile example.description
    APP.run(mod).should == 0
    state = VmState.from_file '/tmp/gene_vm_state.json'
    state.resume.should == 1
  end

end
