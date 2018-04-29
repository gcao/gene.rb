require 'securerandom'
require 'gene/lang/jit/application'
require 'gene/lang/jit/compiler'

module Gene::Lang::Jit
  class Registers < Hash
    attr_reader :id

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

    def [] id
      @store[id]
    end
  end

  # Represents a complete virtual machine that will be used to run
  # the instructions and hold the application state
  class VirtualMachine
    attr_reader :application

    def initialize application
      @application   = application
      @registers_mgr = RegistersManager.new
      @blocks        = {}
    end

    def add_block block
      @blocks[block.key] = block
    end

    def process context, block, options
      @context      = context
      @block        = block
      @registers    = @registers_mgr.create
      @instructions = @block.instructions

      @exec_pos = 0
      @jumped   = false # Set to true if last instruction is a jump
      if options[:debug]
        puts
      end
      while @exec_pos < @instructions.length
        instruction = @instructions[@exec_pos]
        type, arg0, *rest = instruction
        if options[:debug]
          puts "#{@block.name} #{@exec_pos}: #{type} #{instruction[1..-1].to_s.gsub(/[\[\],]/, '')}"
        end

        send type, arg0, *rest

        if @jumped
          @jumped = false
        else
          @exec_pos += 1
        end
      end

      # Result should always be stored in the default register
      @registers['default']
    end

    def self.instr name, &block
      Gene::Lang::Jit.const_set name.upcase, name
      define_method name, &block
    end

    instr 'get' do |reg, path, target_reg|
      value = @registers[reg][path]
      @registers[target_reg] = value
    end

    instr 'set' do |reg, path, value_reg|
      value  = @registers[value_reg]
      target = @registers[reg]

      target[path] = value
    end

    # Define a variable in current context
    instr 'def_member' do |name, value_register = nil|
      if value_register
        value = @registers[value_register]
        @context.def_member name, value
      else
        @context.def_member name
      end
    end

    # Get value of a variable in current context
    instr 'get_member' do |name|
      @registers['default'] = @context.get_member name
    end

    # Set value of a variable in current context
    instr 'set_member' do |name, value|
      puts "set_member: TODO"
    end

    # write "a" 1: write to register 'a'
    instr 'write' do |name, value|
      @registers[name] = value
    end

    # default 1: write 1 to default register
    instr 'default' do |value|
      @registers['default'] = value
    end

    # # TODO: is this needed? copy should cover this
    # # read "a": read from register a and store in default register
    # instr 'read' do |name = nil|
    # end

    # copy "a" "b": copy from register a to register b
    instr 'copy' do |reg1, reg2|
      value = @registers[reg1]
      @registers[reg2]   = value
    end

    # copy "a" "b": copy from a to b and release a
    instr 'copy_release' do
    end

    # label "abc": do nothing, act like an anchor
    instr 'label' do |name|
    end

    instr 'create_obj' do |reg, type, properties, data|
      obj = Gene::Types::Base.new type
      obj.properties = properties
      obj.data       = data
      @registers[reg]    = obj
    end

    instr 'todo' do |code|
      puts "TODO: #{code}"
    end

    # 'start_scope',# start_scope parent: start a new scope, save to a register
    # 'end_scope',  # End/close the current scope

    # Number instructions
    # 'incr',   # incr "a": increment register "a" by 1
    # 'decr',   # decr "a": decrement register "a" by 1
    # 'add',    # add "a" "b" "c":
    # 'sub',
    # 'mul',
    # 'div',
    # 'cmp',    # cmp "a" 1: a == 1

    # String instructions
    # 'substr',
    # 'concat',

    # Array instructions

    # Hash instructions

    # Function instructions
    instr 'fn' do |name, body|
      @registers['default'] = Gene::Lang::Jit::Function.new name, body
    end

    # call block_key options: initialize a block with options
    # options : a hash that contains below keys / values
    #   return_addr: caller block key, next pos
    #   return_reg: caller registers id, register name
    #   args_reg: caller registers id, register name
    instr 'call' do |fn_reg, args_reg, options|
      fn          = @registers[fn_reg]
      args        = @registers[args_reg]
      return_addr = [@block.id, @exec_pos + 1]

      registers_id = @registers.id

      @registers = @registers_mgr.create
      @registers['return_addr'] = return_addr
      @registers['return_reg']  = [registers_id, options['return_reg']]

      @registers['args'] = args

      @block        = @blocks[fn.body]

      @instructions = @block.instructions
      @exec_pos     = 0
      @jumped       = true
    end

    instr 'call_end' do |*args|
      # Copy the result to the return register
      id, reg = @registers['return_reg']
      @registers_mgr[id][reg] = @registers['default']

      block_id, pos = @registers['return_addr']

      # Delete the registers of current block
      @registers_mgr.destroy @registers.id

      # Switch to the caller's registers
      @registers = @registers_mgr[id]

      # Change block and set the position
      @block        = @blocks[block_id]

      @instructions = @block.instructions
      @exec_pos     = pos
      @jumped       = true
    end

    # Control flow instructions

    # jump 1 result: jump to instruction 1 in the block
    instr 'jump' do |pos|
      @jumped   = true
      @exec_pos = pos
    end

    instr 'jump_if_false' do |pos|
      if not @registers['default']
        @jumped   = true
        @exec_pos = pos
      end
    end

    # 'jump_rel',   # jump_rel -1 result: jump back by 1
    # 'jump_out',   # jump_out 'block' 123 result: jump to instruction in another block

    # 'ret', # ret result: jump out and save result in default register
    # 'brk', # brk result:

    # 'if',         # if pos1 pos2: if default register's value is truthy, jump relatively to pos1, otherwise, jump to pos2

    # # Get information by name, save result to reg
    # instr 'info_to_reg' do |name, reg|
    #   if name == 'abc'
    #     @registers[reg] = 'value of abc'
    #   else
    #     raise "TODO: info_to_reg #{name} #{reg}"
    #   end
    # end
  end
end