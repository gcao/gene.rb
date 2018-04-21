require 'securerandom'

module Gene::Lang::Jit
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
      block = mod.primary_block
      if source.is_a? Gene::Types::Base
        if source === VAR_TYPE
          block.add_instr [DEF_MEMBER, source.data.first.to_s]
        else
          # TODO
        end
      elsif source.is_a? Gene::Types::Stream
        source.each do |item|
          compile_ mod, itmod.primary_blockem
        end
      elsif source.is_a? Gene::Types::Symbol
        block.add_instr [GET_MEMBER, source.to_s]
      elsif source.is_a? Array
        # TODO
      elsif source.is_a? Hash
        # TODO
      else
        block.add_instr [DEFAULT, source]
      end
    end

    %W(
      VAR
    ).each do |name|
      const_set "#{name}_TYPE", Gene::Types::Symbol.new(name.downcase)
    end
  end

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

    def to_s indent = nil
      s = "\n(CompiledModule"
      @blocks.each do |key, block|
        if key == @primary_block.key
          key += "__primary"
        end
        s << "\n  ^#{key} " << block.to_s('    ')
      end
      s << "\n)"

      if indent
        s.gsub! "\n", "\n#{indent}"
      end

      s
    end
    alias inspect to_s
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

    def to_s indent = nil
      s = "\n(CompiledBlock"
      @instructions.each do |instr|
        s << "\n  #{instr.inspect}"
      end
      s << "\n)"

      if indent
        s.gsub! "\n", "\n#{indent}"
      end

      s
    end
    alias inspect to_s
  end
end