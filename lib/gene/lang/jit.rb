module Gene::Lang::Jit
  class Application
    attr_reader :instructions

    def initialize instructions
      @instructions = instructions
    end

    def run
      Processor.new.process self
    end
  end

  class Context
    attr_reader :parent
    attr_reader :registers
    attr_accessor :default # Default register

    def initialize parent = nil
      @parent = parent
      @registers = {}
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

    def context
      @stack.current
    end

    def process application
      instructions = application.instructions

      @global = Context.new
      @stack  = Stack.new

      @exec_pos = 0
      result = nil

      while true
        type, arg0, *rest = instructions[@exec_pos]

        if type == APP_END
          break
        end

        result = handle type, arg0, *rest

        @exec_pos += 1
      end

      result
    end

    def handle type, arg0 = nil, *rest
      send "handle_#{type}", arg0, *rest
    end

    def handle_write name, value
      context.write name, value
    end

    def handle_read name
      context.default = context.read name
    end
  end

  [
    'app_begin',
    'app_end',

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
    'ret',    # ret value stored in default register
    'break',
  ].each do |instruction|
    const_set instruction.upcase, instruction
  end
end
