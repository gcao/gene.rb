module Gene::Lang::Jit
  class VmState
    attr_accessor :application
    attr_accessor :registers_mgr
    attr_accessor :modules
    attr_accessor :blocks

    attr_accessor :block
    attr_accessor :registers
    attr_accessor :instructions
    attr_accessor :exec_pos
    attr_accessor :jumped

    def self.from vm
    end
  end
end
