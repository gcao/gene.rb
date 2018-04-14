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
      compile_ mod, source
      mod
    end

    def parse_and_compile string
      parsed = Gene::Parser.parse string
      compile parsed
    end

    def compile_ mod, source
      if source.is_a? Gene::Types::Base
        if source === VAR_TYPE
          mod.primary_block.add_instr [DEFINE, source.data.first.to_s]
        else
          # TODO
        end
      elsif source.is_a? Array
        # TODO
      elsif source.is_a? Hash
        # TODO
      else
        mod.primary_block.add_instr [DEFAULT, source]
      end
    end

    %W(
      VAR
    ).each do |name|
      const_set name, Gene::Types::Symbol.new("#{name.downcase}_TYPE")
    end
  end
end
