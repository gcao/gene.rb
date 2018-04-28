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
        value = source.to_s
        if value == 'break'
          compile_break block, source
        else
          compile_symbol block, source
        end
      elsif source.is_a? Gene::Lang::Statements
        compile_statements block, source
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
      source = Gene::Lang::Transformer.new.call(source)

      if source.type.is_a? Gene::Types::Symbol
        type = source.type.to_s

        if type == "var"
          compile_var block, source
        elsif type == "if$"
          compile_if block, source
        elsif type == "loop"
          compile_loop block, source
        elsif type == "fn$"
          compile_fn block, source
        else
          compile_invocation block, source
        end
      else
        compile_ block, source.type
        # if eval_arguments is true, evaluate arguments
        # invoke function with rest as arguments
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
      compile_ block, source['cond']

      jump1 = block.add_instr [JUMP_IF_FALSE, nil]

      compile_ block, source['then']
      jump2 = block.add_instr [JUMP, nil]

      jump1[1] = block.length

      compile_ block, source['else']

      jump2[1] = block.length
    end

    def compile_loop block, source
      start_pos = block.length
      compile_statements block, source.data
      block.add_instr [JUMP, start_pos]
      start_pos.upto(block.length - 1) do |i|
        instr = block[i]
        if instr[0] == JUMP and instr[1] < 0
          instr[1] = block.length
        end
      end
    end

    def compile_fn block, source
      # Compile function body as a block
      # Function default args are evaluated in the block as well
      body_block      = CompiledBlock.new
      body_block.name = source['name']
      compile_ body_block, source['body']
      @mod.add_block body_block

      # Create a function object and store in namespace/scope
      block.add_instr [FN, source['name'], source['args'], body_block.key]
      block.add_instr [DEF_MEMBER, source['name'].to_s, 'default']
    end

    def compile_invocation block, source
      compile_symbol block, source.type
      reg_fn = new_reg
      block.add_instr [COPY, nil, reg_fn]
      reg_args = nil
      block.add_instr [INVOKE, reg_fn, reg_args]
    end

    def compile_break block, source
      if source.is_a? Gene::Types::Base
        compile_unknown block, source
      else
        block.add_instr [JUMP, -1]
      end
    end

    def compile_symbol block, source
      block.add_instr [GET_MEMBER, source.to_s]
    end

    def compile_statements block, source
      source.each do |item|
        compile_ block, item
      end
    end

    def compile_stream block, source
      source.each do |item|
        compile_ block, item
      end
    end

    def compile_array block, source
      compile_unknown block, source
    end

    def compile_hash block, source
      compile_unknown block, source
    end

    def compile_literal block, source
      block.add_instr [DEFAULT, source]
    end

    def compile_unknown block, source
      block.add_instr ['todo', source.inspect]
    end

    def is_literal? source
      not (source.is_a? Array or source.is_a? Hash or source.is_a? Gene::Types::Base)
    end

    def new_reg
      # TODO add logic to prevent collision - cache all registers assigned so far and check existance
      "R#{rand(100000)}"
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
        else
          key += "__#{block.name}"
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
    attr_accessor :name
    attr_writer :is_default

    def initialize instructions = []
      @key          = SecureRandom.uuid
      @instructions = instructions
    end

    def [] index
      @instructions[index]
    end

    def add_instr instruction
      @instructions << instruction
      instruction
    end

    def size
      @instructions.size
    end
    alias length size

    def is_default?
      @is_default
    end

    def to_s indent = nil
      s = "\n(CompiledBlock"
      @instructions.each_with_index do |instr, i|
        s << "\n  "
        s << "#{i}: #{instr[0]} #{instr[1..-1].to_s.gsub(/^\[/, '').gsub(/\]$/, '').gsub(/, /, ' ')}"
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