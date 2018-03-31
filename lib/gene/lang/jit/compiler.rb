require 'securerandom'

module Gene::Lang::Jit
  class CompiledModule
    attr_reader :blocks
    attr_reader :primary_block

    def initialize primary_block
      @blocks = {}
      self.primary_block = primary_block
    end

    def add_block block
      @blocks[block.key] = block
    end

    def get_block key
      @blocks[key]
    end

    def primary_block= block
      add_block block
      @primary_block = block
    end
  end

  class CompiledBlock
    attr_reader :key, :instructions

    def initialize instructions
      @key          = SecureRandom.uuid
      @instructions = instructions
    end

    def add_instr instruction
      @instructions << instruction
    end
  end

  class Compiler
    def initialize
    end

    # return CompiledModule
    def compile source
      block = CompiledBlock.new []
      mod   = CompiledModule.new block
    end

    def parse_and_compile string
      parsed = Gene::Parser.parse string
      compile parsed
    end
  end
end
