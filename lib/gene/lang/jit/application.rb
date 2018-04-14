module Gene::Lang::Jit
  class Application
    attr_reader :modules
    attr_reader :primary_module

    def initialize primary_module
      @modules        = []
      @primary_module = primary_module
    end

    def run
      VirtualMachine.new.process primary_module
    end
  end
end