require 'securerandom'
require 'gene/lang/jit/application'
require 'gene/lang/jit/compiler'

module Gene::Lang::Jit
  # Registers has a unique id, a default register and other registers
  class Registers < Hash
    attr_reader :id
    attr_accessor :default

    def initialize
      @id = SecureRandom.uuid
    end
  end

  class RegistersManager
    def initialize
      @store = {}
    end

    def create
      registers = Registers.new
      @store[registers.id] = registers
      registers
    end

    def destroy id
      @store.delete id
    end
  end

  # Represents a complete virtual machine that will be used to run
  # the instructions and hold the application state
  class VirtualMachine
    def initialize
      @registers_mgr = RegistersManager.new
      @registers     = @registers_mgr.create
    end

    def process mod
      block        = mod.primary_block
      instructions = block.instructions

      @exec_pos = 0
      result = nil

      while @exec_pos < instructions.length
        type, arg0, *rest = instructions[@exec_pos]

        result = send type, arg0, *rest

        @exec_pos += 1
      end

      result
    end

    def define name, value = nil
    end

    def write name, value
      @registers[name] = value
    end

    def default value
      @registers.default = value
    end

    def read name = nil
      if name
        @registers[name]
      else
        @registers.default
      end
    end
  end

  [
    'define', # Define a variable in current context

    'read',   # read "a": read from register and store in default register
    'write',  # write "a" 1: write to register 'a'
    'default',# default 1: write 1 to default register
    'copy',   # copy "a" "b": copy from one register to another

    # Number instructions
    'incr',   # incr "a": increment register "a" by 1
    'decr',   # decr "a": decrement register "a" by 1
    'add',    # add "a" "b" "c":
    'sub',
    'mul',
    'div',
    'cmp',    # cmp "a" 1: a == 1

    # String instructions
    'substr',
    'concat',

    # Array instructions

    # Hash instructions

    # Control flow instructions
    'jump',       # jump 1 result: jump to instruction 1 in the block
    'jump_rel',   # jump_rel -1 result: jump back by 1
    'jump_out',   # jump_out 'block' 123 result: jump to instruction in another block

    'ret', # ret result: jump out and save result in default register
    'brk',
  ].each do |instruction|
    const_set instruction.upcase, instruction
  end
end