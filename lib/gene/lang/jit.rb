module Gene::Lang::Jit
  # class Context
  #   attr_reader :parent
  #   attr_reader :registers
  #   attr_accessor :default # Default register

  #   def initialize parent = nil
  #     @parent    = parent
  #     @registers = {}
  #   end

  #   def define name, value
  #     @registers[name] = value
  #   end

  #   def write name, value
  #     @registers[name] = value
  #   end

  #   def read name
  #     @registers[name]
  #   end
  # end

  # Stack of registers
  class Stack < Array
    def initialize
      push Context.new
    end

    def current
      self[-1]
    end
  end

  # Represents a complete virtual machine that will be used to run
  # the instructions and hold the application state
  class VirtualMachine

    attr_reader :global

    def initialize
      @global = Context.new
      @stack  = Stack.new
    end

    def context
      @stack.current
    end

    def process mod
      block        = mod.primary_block
      instructions = block.instructions

      @exec_pos = 0
      result = nil

      while @exec_pos < instructions.length
        type, arg0, *rest = instructions[@exec_pos]

        result = handle type, arg0, *rest

        @exec_pos += 1
      end

      result
    end

    def handle type, arg0 = nil, *rest
      send "handle_#{type}", arg0, *rest
    end

    def handle_define name, value = nil
      context.define name, value
    end

    def handle_write name, value
      context.write name, value
    end

    def handle_read name
      context.default = context.read name
    end
  end

  [
    'define', # Define a variable in current context
    'read',   # read "a": read from register and store in default register
    'write',  # write "a" 1: write to register

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
    'jump',   # jump 1: jump to instruction 1 in the block
    'relative_jump', # relative_jump -1: jump back by 1
    'long_jump', # jump to instruction in another block
    'return', # return value stored in default register
    'break',
  ].each do |instruction|
    const_set instruction.upcase, instruction
  end
end

require 'gene/lang/jit/application'
require 'gene/lang/jit/compiler'