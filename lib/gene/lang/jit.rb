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
      @blocks[block.id] = block
    end

    def process block, options
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
          puts "#{@block.name} #{@exec_pos}: #{type} #{instruction[1..-1].to_s.gsub(/^\[/, '').gsub(/\]$/, '').gsub(/, /, ' ')}"
        end

        send "do_#{type}", arg0, *rest

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
      define_method "do_#{name}", &block
    end

    instr 'init' do |options = {}|
      @registers['context'] = @application.create_root_context
    end

    instr 'get' do |reg, path, target_reg|
      value = @registers[reg][path]
      @registers[target_reg] = value
    end

    instr 'set' do |reg, path, value_reg|
      value  = @registers[value_reg]
      target = @registers[reg]

      if value.is_a? Gene::Lang::Jit::Expandable
        if path.is_a? String
          target[path] = value
        else
          target[path..path] = value.value
        end
      else
        target[path] = value
      end
    end

    # Define a variable in current context
    instr 'def_member' do |name, value_reg|
      context = @registers['context']
      if value_reg
        value = @registers[value_reg]
        context.def_member name, value
      else
        context.def_member name
      end
    end

    # Get value of a variable in current context
    instr 'get_member' do |name|
      context = @registers['context']
      if name[-3..-1] == '...'
        @registers['default'] = Gene::Lang::Jit::Expandable.new context.get_member(name[0..-4])
      else
        @registers['default'] = context.get_member name
      end
    end

    # Set value of a variable in current context
    instr 'set_member' do |name, value_reg|
      context = @registers['context']
      value = @registers[value_reg]
      context.set_member name, value
      @registers['default'] = value
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
      raise "TODO: #{code}"
    end

    # 'start_scope',# start_scope parent: start a new scope, save to a register
    # 'end_scope',  # End/close the current scope

    # Number instructions
    # 'incr',   # incr "a": increment register "a" by 1
    # 'decr',   # decr "a": decrement register "a" by 1

    # Handled by [binary first op second]
    # instr 'add' do |reg1, reg2|
    #   result = @registers[reg1] + @registers[reg2]
    #   @registers['default'] = result
    # end

    # 'sub',
    # 'mul',
    # 'div',

    instr 'invert' do |reg|
      @registers[reg] = !@registers[reg]
    end

    instr 'binary' do |first_reg, type, second_reg|
      first  = @registers[first_reg]
      second = @registers[second_reg]
      result  =
        case type
        when '+'
          first + second
        when '-'
          first - second
        when '*'
          first * second
        when '/'
          first / second
        when '=='
          first == second
        when '<'
          first < second
        when '<='
          first <= second
        when '>'
          first > second
        when '>='
          first >= second
        else
          raise "Not supported binary operation: #{op}"
        end

      @registers['default'] = result
    end

    # String instructions
    # 'substr',
    instr 'concat' do |reg1, reg2|
      @registers[reg1] += @registers[reg2].to_s
    end

    # Array instructions
    # TODO: When dynamic is true, treat index arguments as register names
    instr 'get_range' do |reg, start_index, end_index, dynamic = false|
      arr = @registers[reg]
      @registers['default'] = arr[start_index..end_index]
    end

    # Hash instructions

    # Function instructions
    instr 'fn' do |name, body|
      @registers['default'] = Gene::Lang::Jit::Function.new name, body
    end

    # call block_id options: initialize a block with options
    # options : a hash that contains below keys / values
    #   return_addr: caller block id, next pos
    #   return_reg: caller registers id, register name
    #   args_reg: caller registers id, register name
    instr 'call' do |block_id_reg, options|
      caller_regs = @registers
      return_addr = [@block.id, @exec_pos + 1]

      @registers = @registers_mgr.create

      caller_context = caller_regs['context']
      if options['inherit_scope']
        scope_ = Gene::Lang::Jit::Scope.new caller_context.scope, true
      else
        scope = Gene::Lang::Jit::Scope.new
      end
      if options['self_reg']
        self_ = caller_regs[options['self_reg']]
      end
      context = caller_context.extend scope: scope, self: self_
      @registers['context']     = context

      @registers['return_reg']  = [caller_regs.id, options['return_reg']]
      @registers['return_addr'] = return_addr

      if options['fn_arg']
        fn_reg = options['fn_arg']
        fn     = caller_regs[fn_reg]
        @registers['fn'] = fn
      end

      if options['args_reg']
        args_reg    = options['args_reg']
        args        = caller_regs[args_reg]
        @registers['args'] = args
      end

      block_id      = caller_regs[block_id_reg]
      @block        = @blocks[block_id]

      @instructions = @block.instructions
      @exec_pos     = 0
      @jumped       = true
    end

    instr 'call_end' do |*args|
      # Copy the result to the return register
      id, reg = @registers['return_reg']
      if reg
        @registers_mgr[id][reg] = @registers['default']
      end

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

    instr 'call_native' do |target_reg, method, args_reg = nil|
      target = @registers[target_reg]
      args   = args_reg ? @registers[args_reg] : []
      result = target.send method, *args
      @registers['default'] = result
    end

    instr 'call_native_dynamic' do |target_reg, method_reg, args_reg = nil|
      target = @registers[target_reg]
      method = @registers[method_reg]
      args   = args_reg ? @registers[args_reg] : []
      result = target.send method, *args
      @registers['default'] = result
    end

    instr 'class' do |name|
      @registers['default'] = Gene::Lang::Jit::Class.new name
    end

    instr 'module' do |name|
      @registers['default'] = Gene::Lang::Jit::Module.new name
    end

    instr 'get_class' do |reg|
      obj = @registers[reg]
      @registers['default'] = obj.class
    end

    instr 'create_inheritance_hierarchy' do |reg|
      klass = @registers[reg]
      @registers['default'] = Gene::Lang::Jit::HierarchySearch.new(klass.ancestors)
    end

    instr 'method' do |name, block_id|
      fn = Gene::Lang::Jit::Function.new name, block_id
      context = @registers['context']
      self_ = context.self
      self_.add_method fn
      @registers['default'] = fn
    end

    instr 'new' do |class_reg, args_reg|
      klass     = @registers[class_reg]
      instance  = Gene::Lang::Object.new klass

      @registers['default'] = instance

      hierarchy = Gene::Lang::Jit::HierarchySearch.new klass.ancestors
      method    = hierarchy.method 'init', do_not_throw_error: true

      if method
        # Invoke init method
        caller_regs = @registers
        return_addr = [@block.id, @exec_pos + 1]

        @registers  = @registers_mgr.create

        caller_context = caller_regs['context']
        scope   = Gene::Lang::Jit::Scope.new

        context = caller_context.extend scope: scope, self: instance
        @registers['context']     = context

        @registers['return_reg']  = [caller_regs.id, nil]
        @registers['return_addr'] = return_addr

        @registers['args'] = caller_regs[args_reg]

        @block        = @blocks[method.body]

        @instructions = @block.instructions
        @exec_pos     = 0
        @jumped       = true
      end
    end

    instr 'call_method' do |self_reg, method_reg, args_reg, hierarchy_reg|
      caller_regs = @registers
      return_addr = [@block.id, @exec_pos + 1]

      @registers  = @registers_mgr.create

      caller_context = caller_regs['context']
      scope   = Gene::Lang::Jit::Scope.new

      context = caller_context.extend scope: scope, self: caller_regs[self_reg]
      @registers['context']     = context

      @registers['return_reg']  = [caller_regs.id, 'default']
      @registers['return_addr'] = return_addr

      @registers['args'] = caller_regs[args_reg]

      method        = caller_regs[method_reg]
      @block        = @blocks[method.body]

      @instructions = @block.instructions
      @exec_pos     = 0
      @jumped       = true
    end

    # Control flow instructions

    # jump 1 result: jump to instruction 1 in the block
    instr 'jump' do |pos|
      @jumped   = true
      @exec_pos = pos
    end

    instr 'jump_if_true' do |pos|
      if @registers['default']
        @jumped   = true
        @exec_pos = pos
      end
    end

    instr 'jump_if_false' do |pos|
      if not @registers['default']
        @jumped   = true
        @exec_pos = pos
      end
    end

    instr 'throw' do |error_reg|
      message = error_reg ? @registers[error_reg] : "Unknown error"
      raise message
    end

    # 'jump_rel',   # jump_rel -1 result: jump back by 1
    # 'jump_out',   # jump_out 'block' 123 result: jump to instruction in another block

    # 'ret', # ret result: jump out and save result in default register
    # 'brk', # brk result:

    # 'if',         # if pos1 pos2: if default register's value is truthy, jump relatively to pos1, otherwise, jump to pos2

    instr 'print' do |reg, new_line, is_error = false|
      if is_error
        if new_line
          STDERR.puts @registers[reg]
        else
          STDERR.print @registers[reg]
        end
      else
        if new_line
          puts @registers[reg]
        else
          print @registers[reg]
        end
      end
    end

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