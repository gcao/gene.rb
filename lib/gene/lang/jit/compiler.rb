require 'securerandom'

module Gene::Lang::Jit
  class Compiler
    def initialize
    end

    def parse_and_compile string
      parsed = Gene::Parser.parse string
      compile parsed
    end

    # return CompiledModule
    def compile source
      primary_block = CompiledBlock.new []
      @mod          = CompiledModule.new primary_block
      compile_ primary_block, source
      @mod
    end

    def compile_ block, source
      if source.is_a? Gene::Types::Base
        compile_object block, source
      elsif source.is_a? Gene::Types::Symbol
        compile_symbol block, source
      elsif source.is_a? Gene::Types::Stream
        compile_stream block, source
      elsif source.is_a? Array
        compile_array block, source
      elsif source.is_a? Hash
        compile_hash block, source
      else
        compile_literal block, source
      end
    end

    def compile_object block, source
      if source === VAR_TYPE
        compile_var block, source
      elsif source === IF_TYPE
        compile_if block, source
      else
        compile_unknown block, source
      end
    end

    def compile_var block, source, options = {}
      name = source.data.first.to_s
      if source.data.length == 1
        block.add_instr [DEF_MEMBER, name]
      else
        # TODO: compile value, store in default register, define member with value in default
        compile_ block, source.data[1]
        block.add_instr [DEF_MEMBER, name, 'default']
      end
    end

    def compile_if block, source
      compile_unknown block, source
    end

    def compile_symbol block, source
      block.add_instr [GET_MEMBER, source.to_s]
    end

    def compile_stream block, source
      source.each do |item|
        compile_ block, item
      end
    end

    def compile_array block, source
      block.add_instr ['todo', source.inspect]
    end

    def compile_hash block, source
      block.add_instr ['todo', source.inspect]
    end

    def compile_literal block, source
      block.add_instr [DEFAULT, source]
    end

    def compile_statements block, stmts
      block.add_instr ['todo', 'statements']
    end

    def compile_unknown block, source
      block.add_instr ['todo', source.inspect]
    end

    def is_literal? source
      not (source.is_a? Array or source.is_a? Hash or source.is_a? Gene::Types::Base)
    end

    %W(
      var
      if
    ).each do |name|
      const_set "#{name.upcase}_TYPE", Gene::Types::Symbol.new(name)
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

    def add_instr *instructions
      instructions.each do |instruction|
        @instructions << instruction
      end
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