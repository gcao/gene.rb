require 'securerandom'
require 'gene/lang/jit/utils'
require 'gene/lang/jit/application'
require 'gene/lang/jit/compiler'

require 'socket'

module Gene::Lang::Jit
  # Code Manager that manages loading and resolving of modules and blocks
  # When needed, it can be asked to free up all cached modules blocks etc
  class CodeManager
    # The modules can be cleaned up to save memory
    # Context is saved if the module may potentially be reloaded (e.g. thru importing)
    # key: module id
    # val: [path, module]
    attr_reader :module_mappings
    # The blocks can be cleaned up to save memory
    # key: block id
    # val: [module id, block]
    attr_reader :block_mappings
    # key: module path
    # val: module id
    attr_reader :path_to_module_mappings

    def initialize
      @module_mappings = {}
      @block_mappings = {}
      @path_to_module_mappings = {}
    end

    # Load from path, e.g. a/b.gene, a/b.gmod
    def load_from_path path, options = {}
      path.sub! /.(gene|gmod)$/, ''
      module_id = @path_to_module_mappings[path]
      if module_id
        return @module_mappings[module_id]
      end

      mod_file = "#{path}.gmod"
      if File.exist? mod_file
        mod = Gene::Lang::Jit::CompiledModule.from_json File.read(mod_file)
      else
        gene_file = "#{path}.gene"
        parsed    = Gene::Parser.parse File.read(gene_file)
        compiler  = Gene::Lang::Jit::Compiler.new
        mod       = compiler.compile parsed, options
      end

      @module_mappings[mod.id] = mod
      @path_to_module_mappings[path] = mod.id
      add_blocks_from_module mod

      mod
    end

    # # Load compiled module object, map to path if provided
    # def load_compiled_module mod, path = nil
    # end

    # Compile String input and load
    def compile_and_load input
      mod = Gene::Lang::Jit::Compiler.new.compile input

      @module_mappings[mod.id] = mod
      add_blocks_from_module mod

      mod
    end

    def load mod, path = nil
      @module_mappings[mod.id] = mod

      if path
        @path_to_module_mappings[path] = mod.id
      end

      add_blocks_from_module mod
    end

    def get_block id
      @block_mappings[id]
    end

    def add_block block
      @block_mappings[block.id] = block
    end

    private

    def add_blocks_from_module mod
      mod.blocks.each do |id, block|
        @block_mappings[id] = block
      end
    end
  end

  CODE_MGR = CodeManager.new

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

    def add register
      @store[register.id] = register
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
    end

    def load_module mod, options = {}
      CODE_MGR.load mod

      process mod.primary_block, options
    end

    def process block, options
      @block        = block
      @registers    = @registers_mgr.create
      @instructions = @block.instructions

      @exec_pos = 0
      @jumped   = false # Set to true if last instruction is a jump
      while @exec_pos < @instructions.length
        instruction = @instructions[@exec_pos]
        type, arg0, *rest = instruction
        if options[:debug]
          puts "<#{@block.name}>#{@exec_pos.to_s.rjust(4)}: #{type} #{instruction[1..-1].to_s.gsub(/^\[/, '').gsub(/\]$/, '').gsub(/, /, ' ')}"
        end

        send "do_#{type}", arg0, *rest

        if @jumped
          @jumped = false
        else
          @exec_pos += 1
        end
      end

      # Result should always be stored in the default register
      result = @registers['default']
      # TODO: clean up

      if result.is_a? Function
        # Save application object to allow invocation from Ruby code
        result.app = @application
      end

      result
    end

    # No need to compile, manually create registers, store arguments and invoke call instruction
    # Q: how about context?
    # A: function should have a reference to the namespace and scope it inherits, a context will be
    #    constructed from those automatically by 'call'
    def process_function f, args, options = {}
      fn_reg   = 'temp1'
      args_reg = 'temp2'

      block = CompiledBlock.new
      CODE_MGR.add_block block
      block.add_instr [INIT]
      block.add_instr [WRITE, fn_reg, f]

      # Create argument object and add to a register
      args_obj = Gene::Lang::Object.new
      args_obj.data = args
      block.add_instr [WRITE, args_reg, args_obj]

      block.add_instr [DEFAULT, f.body]

      # Call function
      block.add_instr [CALL, 'default', {
        'fn_reg'     => fn_reg,
        'args_reg'   => args_reg,
        'return_reg' => 'default',
      }]

      process block, options
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

    instr 'global' do |_|
      @registers['default'] = @application.global
    end

    instr 'args' do |_|
      @registers['default'] = ARGV
    end

    # Define a variable in current context
    instr 'def_member' do |name, value_reg, options = {}|
      context = @registers['context']
      if value_reg
        value = @registers[value_reg]
        context.def_member name, value, options
      else
        context.def_member name, nil, options
      end
    end

    instr 'undef_member' do |name|
      context.undef_member name
    end

    # Get value of a variable in current context
    instr 'get_member' do |name|
      context = @registers['context']
      if name[-3..-1] == '...'
        @registers['default'] = Gene::Lang::Jit::Expandable.new context.get_member(name[0..-4])
      elsif name == 'gene'
        @registers['default'] = @application.global.get_member 'gene'
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

    instr 'def_child_member' do |reg, name, value_reg|
      obj = @registers[reg]
      obj.def_member name, @registers[value_reg]
    end

    instr 'get_child_member' do |reg, name|
      obj = @registers[reg]
      @registers['default'] = obj.get_member name
    end

    instr 'set_child_member' do |reg, name, value_reg|
      obj = @registers[reg]
      obj.set_member name, @registers[value_reg]
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

    # # copy "a" "b": copy from a to b and release a
    # instr 'copy_release' do
    # end

    instr 'create_obj' do |type_reg, properties_reg, data_reg|
      type       = @registers[type_reg]
      if properties_reg.is_a? String
        properties = @registers[properties_reg]
      else
        properties = properties_reg
      end
      if data_reg.is_a? String
        data       = @registers[data_reg]
      else
        data       = data_reg
      end

      obj = Gene::Types::Base.new type
      obj.properties = properties
      obj.data       = data

      @registers['default'] = obj
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

    instr 'symbol' do |s|
      @registers['default'] = Gene::Types::Symbol.new(s)
    end

    instr 'stream' do |_|
      @registers['default'] = Gene::Types::Stream.new
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
    instr 'fn' do |name, body, options|
      context = @registers['context']
      fn = Gene::Lang::Jit::Function.new name, body, options
      fn.namespace = context.namespace
      if fn.inherit_scope
        fn.scope = context.scope
      end
      @registers['default'] = fn
    end

    # TCO (Tail Call Optimization)
    # Check whether next instruction is call_end
    #   or if next instruction is jump
    #     if yes, repeat above check
    # If it's a tail call
    #   re-use registers object
    #   TODO: clear temporary registers

    # call block_id options: initialize a block with options
    # options : a hash that contains below keys / values
    #   return_addr: caller block id, next pos
    #   return_reg: caller registers id, register name
    #   args_reg: caller registers id, register name
    instr 'call' do |block_id_reg, options|
      if self.is_tail_call?(options)
        if not @registers['return_reg']
          @registers['return_reg'] = [@registers.id, options['return_reg']]
        end
        if not @registers['return_addr']
          @registers['return_addr'] = [@block.id, @exec_pos + 1]
        end

        fn_reg = options['fn_reg']
        fn     = @registers[fn_reg]
        @registers['fn'] = fn
        inherit_scope = fn.inherit_scope
        parent_scope  = fn.scope

        if inherit_scope
          scope = Gene::Lang::Jit::Scope.new parent_scope, true
        else
          scope = Gene::Lang::Jit::Scope.new
        end

        if options['self_reg']
          self_ = @registers[options['self_reg']]
        end

        namespace = fn.namespace
        context = Gene::Lang::Jit::Context.new namespace, scope, self_
        @registers['context']     = context

        if options['args_reg']
          args_reg    = options['args_reg']
          args        = @registers[args_reg]
          @registers['args'] = args
        end

        block_id      = @registers[block_id_reg]
        @block        = CODE_MGR.get_block(block_id)

        @instructions = @block.instructions
        @exec_pos     = 0
        @jumped       = true
        break
      end

      caller_regs = @registers
      return_addr = [@block.id, @exec_pos + 1]
      caller_context = caller_regs['context']

      @registers = @registers_mgr.create

      inherit_scope = options['inherit_scope']
      parent_scope  = caller_context.scope

      if options['fn_reg']
        fn_reg = options['fn_reg']
        fn     = caller_regs[fn_reg]
        @registers['fn'] = fn
        inherit_scope = fn.inherit_scope
        parent_scope  = fn.scope

        if fn.is_a? Gene::Lang::Jit::Continuation
          # Restore or save the registers in the continuation object
          if fn.registers
            # Discard the newly-created registers
            @registers_mgr.destroy @registers

            @registers = fn.registers
            @registers_mgr.add @registers

            @registers['return_addr'] = return_addr

            # Only one argument is accepted
            args_reg    = options['args_reg']
            args        = caller_regs[args_reg]
            @registers['default'] = args[0]

            block_id      = caller_regs[block_id_reg]
            @block        = CODE_MGR.get_block(block_id)

            @instructions = @block.instructions
            @exec_pos     = fn.next_pos
            @jumped       = true
            return
          else
            fn.registers = @registers
          end
        end
      end

      if inherit_scope
        scope = Gene::Lang::Jit::Scope.new parent_scope, true
      else
        scope = Gene::Lang::Jit::Scope.new
      end

      if options['self_reg']
        self_ = caller_regs[options['self_reg']]
      end

      if fn
        namespace = fn.namespace
      elsif options['namespace_reg']
        namespace = caller_regs[options['namespace_reg']]
      else
        namespace = caller_context.namespace
      end

      context = Gene::Lang::Jit::Context.new namespace, scope, self_
      @registers['context']     = context

      @registers['return_reg']  = [caller_regs.id, options['return_reg']]
      @registers['return_addr'] = return_addr

      if options['args_reg']
        args_reg    = options['args_reg']
        args        = caller_regs[args_reg]
        @registers['args'] = args
      end

      block_id      = caller_regs[block_id_reg]
      @block        = CODE_MGR.get_block(block_id)

      @instructions = @block.instructions
      @exec_pos     = 0
      @jumped       = true
    end

    def is_tail_call? options
      if options['fn_reg']
        pos = @exec_pos + 1
        instr = @instructions[pos]

        while instr && instr[0] == 'jump'
          pos = instr[1]
          instr = @instructions[pos]
        end

        return instr && instr[0] == 'call_end'
      end

      false
    end

    instr 'call_end' do |_|
      # Copy the result to the return register
      id, reg = @registers['return_reg']
      if reg
        @registers_mgr[id][reg] = @registers['default']
      end

      block_id, pos = @registers['return_addr']
      if not block_id
        return
      end

      # Special case for tail call
      if id != @registers.id
        # Delete the registers of current block
        @registers_mgr.destroy @registers.id

        # Switch to the caller's registers
        @registers = @registers_mgr[id]
      end

      # Special case for tail call
      if block_id == @block.id and pos == @exec_pos
        break
      end

      # Change block and set the position
      @block        = CODE_MGR.get_block(block_id)

      @instructions = @block.instructions
      @exec_pos     = pos
      @jumped       = true
    end

    instr 'label' do |name|
      labels = @registers['labels'] ||= {}
      labels[name] = {
        pos: @exec_pos,
      }
    end

    instr 'goto' do |name|
      label = @registers['labels'][name]
      @exec_pos = label[:pos]
      @jumped   = true
    end

    instr 'callcc' do |reg|
      fn = @registers[reg]
      @registers['default'] = Gene::Lang::Jit::Continuation.new fn
    end

    instr 'yield' do |value_reg|
      # Copy value in caller's default register
      id, reg = @registers['return_reg']
      caller_registers = @registers_mgr[id]
      caller_registers[reg] = @registers['default']

      # Update continuation's execution position
      continuation = @registers['fn']
      continuation.next_pos = @exec_pos + 1

      # Switch to caller's block
      caller_block_id, pos = @registers['return_addr']
      @block        = CODE_MGR.get_block(caller_block_id)
      @instructions = @block.instructions
      @exec_pos     = pos
      @jumped       = true

      # Delete the registers of current block
      @registers_mgr.destroy @registers.id

      # Switch to the caller's registers
      @registers = caller_registers
    end

    instr 'call_native' do |target_reg, method, args_reg = nil|
      target = @registers[target_reg]
      args   = args_reg ? @registers[args_reg] : []
      result = target.send method, *args
      @registers['default'] = result
    end

    instr 'call_internal' do |name|
      result = Gene::UNDEFINED

      if name == 'gene_invoke'
        target, method, *args = @registers['default']
        if target.is_a?(TCPServer) or target.is_a?(TCPSocket)
          result = Object.instance_method(:send).bind(target).call method, *args
        else
          result = target.send method, *args
        end
      elsif name == 'gene_get_class'
        class_name   = @registers['default'][0]
        result = Class.const_get(class_name)
      elsif name == 'gene_file_read'
        file   = @registers['default'][0]
        result = File.read file
      elsif name == 'gene_file_read_lines'
        file   = @registers['default'][0]
        result = File.readlines file
      elsif name == 'gene_file_write'
        file, content = @registers['default']
        File.write file, content
      elsif name == 'gene_env_get'
        name   = @registers['default'][0]
        result = ENV[name]
      elsif name == 'gene_env_set'
        name, value = @registers['default']
        ENV[name] = value
      else
        raise "NOT IMPLEMENTED: #{name}"
      end

      @registers['default'] = result
    end

    instr 'ns' do |name|
      context = @registers['context']
      ns = Gene::Lang::Jit::Namespace.new name, context.namespace
      @registers['default'] = ns
    end

    instr 'class' do |name|
      context = @registers['context']
      klass = Gene::Lang::Jit::Class.new name
      klass.parent_namespace = context.namespace
      @registers['default'] = klass
    end

    instr 'module' do |name|
      context = @registers['context']
      mod = Gene::Lang::Jit::Module.new name
      mod.parent_namespace = context.namespace
      @registers['default'] = mod
    end

    instr 'get_class' do |reg|
      obj = @registers[reg]
      # @registers['default'] = obj.class
      cls = obj.class
      if cls == String
        cls = @application.global.get_member('gene').get_member('String')
      elsif cls == Array
        cls = @application.global.get_member('gene').get_member('Array')
      elsif cls == Hash
        cls = @application.global.get_member('gene').get_member('Map')
      end
      @registers['default'] = cls
    end

    instr 'create_inheritance_hierarchy' do |reg|
      klass = @registers[reg]
      @registers['default'] = Gene::Lang::Jit::HierarchySearch.new(klass.ancestors)
    end

    instr 'method' do |name, block_id|
      context = @registers['context']
      self_ = context.self
      if name == 'init' and not self_.is_a? Gene::Lang::Jit::Class
        raise "init is only allowed in a class."
      end
      fn = Gene::Lang::Jit::Function.new name, block_id, inherit_scope: false
      fn.namespace = self_
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

        @block        = CODE_MGR.get_block(method.body)

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
      @block        = CODE_MGR.get_block(method.body)

      @registers['method']    = method
      @registers['hierarchy'] = caller_regs[hierarchy_reg]

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
      @error = error_reg ? @registers[error_reg] : "Unknown error"
      @error_handled = false
      handle_exception
    end

    instr 'add_error_handlers' do |handlers|
      groups = @registers['error_handlers']
      if not groups
        groups = ErrorHandlerGroups.new
        @registers['error_handlers'] = groups
      end
      groups << handlers
    end

    # Check whether the thrown exception is handled by the object in default register
    # If yes, mark the exception as caught/handled and continue
    # If not, jump to next catch block or out of current block
    instr 'check_exception' do |_|
      if true
        @error_handled = true
        # Clear catches for current try statement
        @registers['error_handlers'].pop
      else
        @error_handled = false
        # Clear current catch and continue
        @registers['error_handlers'].pop_handler
        handle_exception
      end
    end

    instr 'clear_exception' do |_|
      @error = nil
    end

    # trigger error handling logic in current block, or end the call
    # or raise error if at the root level
    def handle_exception
      if not @error
        return
      end

      error_handlers = @registers['error_handlers']

      if error_handlers and not error_handlers.empty?
        @exec_pos = error_handlers.pop_handler
        @jumped   = true
      elsif @registers['return_addr']
        # go up and try handle_exception again
        block_id, pos = @registers['return_addr']
        if not block_id
          raise @error
        end

        # Delete the registers of current block
        @registers_mgr.destroy @registers.id

        # Switch to the caller's registers
        @registers = @registers_mgr[id]

        # Change block and set the position
        @block        = CODE_MGR.get_block(block_id)

        @instructions = @block.instructions
        @exec_pos     = pos
        @jumped       = true

        handle_exception
      else
        raise @error
      end
    end

    # 'jump_rel',   # jump_rel -1 result: jump back by 1
    # 'jump_out',   # jump_out 'block' 123 result: jump to instruction in another block

    # 'ret', # ret result: jump out and save result in default register
    # 'brk', # brk result:

    # 'if',         # if pos1 pos2: if default register's value is truthy, jump relatively to pos1, otherwise, jump to pos2

    instr 'load' do |reg, loaded_context_reg|
      path = @registers[reg]
      @registers['default'] = CODE_MGR.load_from_path path, skip_init: true

      do_run 'default', 'save_context_to_reg' => loaded_context_reg
    end

    instr 'compile' do |stmts_reg|
      stmts = Gene::Lang::Statements.new @registers[stmts_reg]
      mod   = Compiler.new.compile(stmts, skip_init: true)
      CODE_MGR.load mod

      @registers['default'] = mod
    end

    instr 'run' do |mod_reg, options = {}|
      mod = @registers[mod_reg]

      caller_regs = @registers
      return_addr = [@block.id, @exec_pos + 1]

      @registers = @registers_mgr.create

      caller_context = caller_regs['context']

      scope = Gene::Lang::Jit::Scope.new caller_context.scope, true
      self_ = caller_regs['self']
      context = caller_context.extend scope: scope, self: self_
      @registers['context']     = context

      save_context_to_reg = options['save_context_to_reg']
      if save_context_to_reg
        caller_regs[save_context_to_reg] = context
      end

      @registers['return_reg']  = [caller_regs.id, 'default']
      @registers['return_addr'] = return_addr

      block_id      = mod.primary_block.id
      @block        = CODE_MGR.get_block(block_id)

      @instructions = @block.instructions
      @exec_pos     = 0
      @jumped       = true
    end

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

    # Help to understand how instructions are related
    instr 'comment' do |_|
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

  class ErrorHandlerGroups < Array
    def pop_handler
      if empty?
        return
      end

      handler = last.pop
      if last.empty?
        pop
      end
      handler
    end
  end
end
