module Gene::Lang::Jit
  class VmState
    include Gene::Utils

    attr_accessor :app
    attr_accessor :vm
    attr_accessor :code_mgr

    # Create a VmState from a running vm
    def self.from_vm vm
      state = new
      state.app = Gene::Lang::Jit::APP
      state.vm = vm
      state.code_mgr = Gene::Lang::Jit::CODE_MGR
      state
    end

    def self.from_file file
      Marshal.load File.read(file)
    end

    # Save json to file
    def save file
      File.write file, Marshal.dump(self)
    end

    # Update application object
    # Update CODE_MGR13k
    # Kick it off
    def resume
      silence_warnings do
        Gene::Lang::Jit.const_set :APP, app
        Gene::Lang::Jit.const_set :CODE_MGR, code_mgr
      end
      vm.run
    end
  end
end
