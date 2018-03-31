module Gene::Lang::Jit
  class Context
    attr_reader :parent
    attr_reader :registers
    attr_accessor :default # Default register

    def initialize parent = nil
      @parent    = parent
      @registers = {}
    end

    def define name, value
      @registers[name] = value
    end

    def write name, value
      @registers[name] = value
    end

    def read name
      @registers[name]
    end
  end

  # Stack of contexts
  class Stack < Array
    def initialize
      push Context.new
    end

    def current
      self[-1]
    end
  end

  class Processor
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
    'read',   # read from register and store in default register
    'write',  # write to register
    'copy',   # copy from one register to another register

    # Number instructions
    'incr',   # increment variable by 1
    'decr',   # decrement variable by 1
    'add',
    'sub',
    'mul',
    'div',
    'cmp',

    # String instructions
    'substr',
    'concat',

    # Array instructions

    # Hash instructions

    # Control flow instructions
    'jump',   # jump to instruction
    'long_jump', # jump to instruction in another block
    'return', # return value stored in default register
    'break',
  ].each do |instruction|
    const_set instruction.upcase, instruction
  end
end

require 'gene/lang/jit/application'
require 'gene/lang/jit/compiler'