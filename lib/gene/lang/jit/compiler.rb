require 'securerandom'
require 'json'

module Gene::Lang::Jit
  class Compiler
    include Utils

    def initialize
    end

    def parse_and_compile string
      parsed = Gene::Parser.parse string
      compile parsed
    end

    # Options:
    #   skip_init: do not add INIT instruction
    # return CompiledModule
    def compile source, options = {}
      primary_block = CompiledBlock.new []
      primary_block.is_default = true
      if not options[:skip_init]
        primary_block.add_instr [INIT]
      end
      @mod = CompiledModule.new primary_block
      compile_ primary_block, source
      @mod
    end

    def compile_ block, source, options = {}
      source = process_decorators source

      if source.is_a? Gene::Types::Base
        compile_object block, source, options
      elsif source.is_a? Gene::Types::Symbol
        compile_symbol block, source, options
      elsif source.is_a? Gene::Lang::Statements
        compile_statements block, source
      elsif source.is_a? Gene::Types::Stream
        compile_stream block, source
      elsif source.is_a? Array
        compile_array block, source, options
      elsif source.is_a? Hash
        compile_hash block, source, options
      else
        compile_literal block, source
      end
    end

    ASSIGN = Gene::Types::Symbol.new('=')

    EQ = Gene::Types::Symbol.new('==')
    LT = Gene::Types::Symbol.new('<')
    LE = Gene::Types::Symbol.new('<=')
    GT = Gene::Types::Symbol.new('>')
    GE = Gene::Types::Symbol.new('>=')

    AND = Gene::Types::Symbol.new('&&')
    OR  = Gene::Types::Symbol.new('||')

    PLUS  = Gene::Types::Symbol.new('+')
    MINUS = Gene::Types::Symbol.new('-')
    MULTI = Gene::Types::Symbol.new('*')
    DIV   = Gene::Types::Symbol.new('/')

    PLUS_EQ  = Gene::Types::Symbol.new('+=')
    MINUS_EQ = Gene::Types::Symbol.new('-=')
    MULTI_EQ = Gene::Types::Symbol.new('*=')
    DIV_EQ   = Gene::Types::Symbol.new('/=')

    BINARY_OPS = [
      ASSIGN,
      AND, OR,
      EQ, LT, LE, GT, GE,
      PLUS, MINUS, MULTI, DIV,
      PLUS_EQ, MINUS_EQ, MULTI_EQ, DIV_EQ,
    ]

    def compile_object block, source, options = {}
      if not options[:template_mode]
        source = Gene::Lang::Transformer.new.call(source)
      end

      op = source.data[0]

      if options[:template_mode]
        compile_ block, source.type, options
        type_reg = copy_and_return_reg block

        compile_ block, source.properties, options
        props_reg = copy_and_return_reg block

        compile_ block, source.data, options

        block.add_instr [CREATE_OBJ, type_reg, props_reg, 'default']

      elsif op.is_a? Gene::Types::Symbol and op.name[0] == '.'
        compile_method_invocation block, source

      elsif BINARY_OPS.include?(op)
        if [EQ, LT, LE, GT, GE].include? op
          compile_ block, source.type
          first_reg  = copy_and_return_reg block

          compile_ block, source.data[1]
          block.add_instr [BINARY, first_reg, op.to_s, 'default']

        elsif [PLUS, MINUS, MULTI, DIV].include? op
          compile_ block, source.type
          first_reg  = copy_and_return_reg block

          compile_ block, source.data[1]
          block.add_instr [BINARY, first_reg, op.to_s, 'default']

        elsif op == AND
          compile_ block, source.type
          # Skip evaluating second expression if false
          jump = block.add_instr [JUMP_IF_FALSE, nil]
          compile_ block, source.data[1]
          jump[1] = block.length

        elsif op == OR
          compile_ block, source.type
          # Skip evaluating second expression if false
          jump = block.add_instr [JUMP_IF_TRUE, nil]
          compile_ block, source.data[1]
          jump[1] = block.length

        elsif op == ASSIGN
          compile_ block, source.data[1]
          target = source.type.to_s
          if target[0] == '@'
            value_reg = copy_and_return_reg block
            block.add_instr [CALL_NATIVE, 'context', 'self']
            block.add_instr [SET, 'default', target[1..-1], value_reg]
          else
            block.add_instr [SET_MEMBER, target, 'default']
          end

        elsif [PLUS_EQ, MINUS_EQ, MULTI_EQ, DIV_EQ].include? op
          compile_ block, source.data[1]
          value_reg = copy_and_return_reg block

          target = source.type.to_s
          if target[0] == '@'
            # TODO: test this
            target = target[1..-1]
            block.add_instr [CALL_NATIVE, 'context', 'self']
            self_reg = copy_and_return_reg block

            # Get @x's value
            block.add_instr [GET, self_reg, target]

            # @x <op> <right value>
            block.add_instr [BINARY, 'default', op.to_s[0], value_reg]

            # @x = <new value>
            block.add_instr [SET, self_reg, target, 'default']
          else
            block.add_instr [GET_MEMBER, target]
            block.add_instr [BINARY, 'default', op.to_s[0], value_reg]
            block.add_instr [SET_MEMBER, target, 'default']
          end

        else
          compile_unknown block, source
        end

      elsif source.type.is_a? Gene::Types::Symbol
        type = source.type.to_s

        if type[0] == "."
          compile_short_method_invocation block, source
        elsif type == "::"
          compile_template block, source
        elsif type == "var"
          compile_var block, source
        elsif type == "if$"
          compile_if block, source
        elsif type == "loop"
          compile_loop block, source
        elsif type == "for"
          compile_for block, source
        elsif type == "fn$"
          compile_fn block, source
        elsif type == "class$"
          compile_class block, source
        elsif type == "module"
          compile_module block, source
        elsif type == "method$"
          compile_method block, source
        elsif type == "new"
          compile_new block, source
        elsif type == "init"
          compile_init block, source
        elsif type == "super"
          compile_super block, source
        elsif type == "ns"
          compile_namespace block, source
        elsif type == "import$"
          compile_import block, source
        elsif type == "return"
          compile_return block, source
        elsif type == "break"
          compile_break block, source
        elsif type == "!"
          compile_invert block, source
        elsif type == "eval"
          compile_eval block, source
        elsif type == "$invoke"
          compile_invoke block, source
        elsif type == "assert"
          compile_assert block, source
        elsif type == "print"
          compile_print block, source
        else
          compile_invocation block, source
        end

      elsif source.type.is_a? String
        compile_string block, source

      else
        compile_unknown block, source
        # compile_ block, source.type
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

    def compile_for block, source
      init, cond, update, *rest = source.data

      compile_ block, init

      cond_pos = block.length
      compile_ block, cond
      cond_jump = block.add_instr [JUMP_IF_FALSE, nil]

      compile_ block, Gene::Lang::Statements.new(rest)

      compile_ block, update
      block.add_instr [JUMP, cond_pos]

      cond_jump[1] = block.length
    end

    def compile_break block, source
      block.add_instr [JUMP, -1]
    end

    def compile_fn block, source
      # Compile function body as a block
      # Function default args are evaluated in the block as well
      body_block      = CompiledBlock.new
      body_block.name = source['name']

      # Arguments & default values
      args = source['args']
      args.data_matchers.each do |matcher|
        if matcher.end_index.nil?
          body_block.add_instr [GET, 'args', matcher.index, 'default']
        else
          body_block.add_instr [GET_RANGE, 'args', matcher.index, matcher.end_index]
        end
        body_block.add_instr [DEF_MEMBER, matcher.name, 'default']
      end

      compile_ body_block, source['body']
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a function object and store in namespace/scope
      block.add_instr [FN, source['name'], body_block.id]
      block.add_instr [DEF_MEMBER, source['name'].to_s, 'default']
    end

    def compile_invocation block, source
      compile_symbol block, source.type

      fn_reg = copy_and_return_reg block

      args_reg = compile_args block, source

      block.add_instr [CALL_NATIVE, fn_reg, 'body']

      block.add_instr [CALL, 'default', {
        'fn_reg'     => fn_reg,
        'args_reg'   => args_reg,
        'return_reg' => 'default',
      }]
    end

    # Compile everything in template mode
    # Symbols are not dereferenced
    # Binary or other expressions are not compiled
    # %x or (%x ...) will be compiled or evaluated when the template is rendered
    # Templates and code can be nested on multiple levels
    def compile_template block, source
      if source.data.length != 1
        compile_ block, Gene::Types::Stream.new(*source.data), template_mode: true
      else
        first = source.data[0]
        compile_ block, first, template_mode: true
      end
    end

    # Process %x and (%x ...) inside template
    def compile_render block, source
      raise "TODO: #{source}"
    end

    def compile_return block, source
      compile_ block, source.data[0]
      block.add_instr [CALL_END]
    end

    def compile_invert block, source
      compile_ block, source.data[0]
      block.add_instr [INVERT, 'default']
    end

    # Arguments are compiled and processed first
    # Results are treated as statements
    # Statements are compiled to a CompiledModule
    # The default block will be invoked
    def compile_eval block, source
      compile_array block, source.data
      block.add_instr [COMPILE, 'default']
      block.add_instr [RUN, 'default']
    end

    def compile_symbol block, source, options = {}
      if options[:template_mode]
        block.add_instr [SYMBOL, source.to_s]
        return
      end

      str = source.to_s
      if str[0] == '@'
        block.add_instr [CALL_NATIVE, 'context', 'self']
        block.add_instr [GET, 'default', str[1..-1], 'default']
      elsif str[0] == ':'
        block.add_instr [SYMBOL, str[1..-1]]
      elsif str == "self"
        block.add_instr [CALL_NATIVE, 'context', 'self']
      else
        first, *rest = str.split '/'
        block.add_instr [GET_MEMBER, first]
        rest.each do |item|
          block.add_instr [GET_CHILD_MEMBER, 'default', item]
        end
      end
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

    def compile_array block, source, options = {}
      if is_literal? source
        block.add_instr [DEFAULT, source]
      else
        result = []
        reg    = new_reg
        block.add_instr [WRITE, reg, result]

        source.each_with_index do |value, index|
          if is_literal? value
            result[index] = value
          else
            compile_ block, value, options
            block.add_instr [SET, reg, index, 'default']
          end
        end

        block.add_instr [COPY, reg, 'default']
      end
    end

    def compile_hash block, source, options = {}
      if is_literal? source
        block.add_instr [DEFAULT, source]
      else
        result = {}
        reg    = new_reg
        block.add_instr [WRITE, reg, result]

        source.each do |key, value|
          if is_literal? value
            result[key] = value
          else
            compile_ block, value
            block.add_instr [SET, reg, key, 'default']
          end
        end

        block.add_instr [COPY, reg, 'default']
      end
    end

    def compile_class block, source
      name        = source['name'].to_s
      body        = source['body']
      super_class = source['super_class']

      # Compile body as a block
      body_block      = CompiledBlock.new
      body_block.name = name

      compile_ body_block, body
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a class object and store in namespace/scope
      block.add_instr [CLASS, name]
      block.add_instr [DEF_MEMBER, name, 'default']

      class_reg = copy_and_return_reg block

      if super_class
        compile_ block, super_class
        block.add_instr [CALL_NATIVE, class_reg, 'parent_class=', 'default']
      end

      # Invoke block immediately and remove it to reduce memory usage
      block.add_instr [DEFAULT, body_block.id]
      block.add_instr [CALL, 'default', {
        'inherit_scope' => false,
        'self_reg' => class_reg,
      }]

      # Return the class
      block.add_instr [COPY, class_reg, 'default']
    end

    def compile_module block, source
      name = source.data[0].to_s
      body = source.data[1..-1]

      # Compile body as a block
      body_block      = CompiledBlock.new
      body_block.name = name

      compile_ body_block, body
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a class object and store in namespace/scope
      block.add_instr [MODULE, name]
      block.add_instr [DEF_MEMBER, name, 'default']
      class_reg = copy_and_return_reg block

      # Invoke block immediately and remove it to reduce memory usage
      block.add_instr [DEFAULT, body_block.id]
      block.add_instr [CALL, 'default', {
        'inherit_scope' => false,
        'self_reg' => class_reg,
      }]

      # Return the class
      block.add_instr [COPY, class_reg, 'default']
    end

    # Compile method body as a block
    # Default args are evaluated in the block as well
    def compile_method block, source
      body_block      = CompiledBlock.new
      body_block.name = source['name']

      # Arguments & default values
      args = source['args']
      args.data_matchers.each do |matcher|
        body_block.add_instr [GET, 'args', matcher.index, 'default']
        body_block.add_instr [DEF_MEMBER, matcher.name, 'default']
      end

      compile_ body_block, source['body']
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a function object and store in namespace/scope
      block.add_instr [METHOD, source['name'], body_block.id]
    end

    # Compile method body as a block
    # Default args are evaluated in the block as well
    def compile_init block, source
      method_name = 'init'

      body_block      = CompiledBlock.new
      body_block.name = method_name

      # Arguments & default values
      args = Gene::Lang::Matcher.from_array source.data.first
      args.data_matchers.each do |matcher|
        body_block.add_instr [GET, 'args', matcher.index, 'default']
        body_block.add_instr [DEF_MEMBER, matcher.name, 'default']
      end

      compile_ body_block, source.data[1..-1]
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a function object and store in namespace/scope
      block.add_instr [METHOD, method_name, body_block.id]
    end

    def compile_new block, source
      compile_ block, source.data.first
      class_reg = copy_and_return_reg block

      args_reg = compile_args block, source, true

      block.add_instr [NEW, class_reg, args_reg]
    end

    # Get class of object
    # Get class hierarchy
    # Get method from hierarchy
    # If method's eval_arguments option is false, do not eval arguments (same as function)
    # Call method with self object, arguments, class, hierarchy (is useful when super is invoked)
    def compile_method_invocation block, source
      compile_ block, source.type

      self_reg = copy_and_return_reg block

      block.add_instr [GET_CLASS, self_reg]

      # Create a hierarchy for class stored in default register
      block.add_instr [CREATE_INHERITANCE_HIERARCHY, 'default']

      hierarchy_reg = copy_and_return_reg block

      method_name     = source.data.first.to_s[1..-1]
      method_name_reg = new_reg

      block.add_instr [WRITE, method_name_reg, method_name]

      # Get the method object from the hierarchy and save to default register
      block.add_instr [CALL_NATIVE, 'default', 'method', method_name_reg]

      method_reg = copy_and_return_reg block

      args_reg   = compile_args block, source, true

      block.add_instr [CALL_METHOD, self_reg, method_reg, args_reg, hierarchy_reg]
    end

    # Get class of object
    # Get class hierarchy
    # Get method from hierarchy
    # If method's eval_arguments option is false, do not eval arguments (same as function)
    # Call method with self object, arguments, class, hierarchy (is useful when super is invoked)
    def compile_short_method_invocation block, source
      block.add_instr [CALL_NATIVE, 'context', 'self']

      self_reg = copy_and_return_reg block

      block.add_instr [GET_CLASS, self_reg]

      # Create a hierarchy for class stored in default register
      block.add_instr [CREATE_INHERITANCE_HIERARCHY, 'default']

      hierarchy_reg = copy_and_return_reg block

      method_name     = source.type.to_s[1..-1]
      method_name_reg = new_reg

      block.add_instr [WRITE, method_name_reg, method_name]

      # Get the method object from the hierarchy and save to default register
      block.add_instr [CALL_NATIVE, 'default', 'method', method_name_reg]

      method_reg = copy_and_return_reg block

      # Treat arguments the same way as function arguments
      args_reg   = compile_args block, source

      block.add_instr [CALL_METHOD, self_reg, method_reg, args_reg, hierarchy_reg]
    end

    # Get hierarchy from hierarchy register (if not found, throw error?)
    def compile_super block, source
      hierarchy_reg   = 'hierarchy'

      # Get method name
      block.add_instr [CALL_NATIVE, 'method', 'name']

      # Get the method object from the hierarchy and save to default register
      block.add_instr [CALL_NATIVE, hierarchy_reg, 'method', 'default']

      method_reg = block.add_instr [COPY, 'default', method_reg]

      # TODO: (super!) will re-use the arguments
      args_reg = compile_args block, source, true

      block.add_instr [CALL_NATIVE, 'context', 'self']

      block.add_instr [CALL_METHOD, 'default', method_reg, args_reg, hierarchy_reg]
    end

    # Compile args
    # Save to a register
    # @return the regiser address
    def compile_args block, source, is_method = false
      compile_ block, source.properties
      props_reg = copy_and_return_reg block

      args_data = is_method ? source.data[1..-1] : source.data

      compile_ block, args_data
      data_reg = copy_and_return_reg block

      block.add_instr [CREATE_OBJ, nil, props_reg, data_reg]
      args_reg = copy_and_return_reg block

      args_reg
    end

    def compile_namespace block, source
      name = source.data[0].to_s
      body = source.data[1..-1]

      # Compile body as a block
      body_block      = CompiledBlock.new
      body_block.name = name

      compile_ body_block, body
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a class object and store in namespace/scope
      block.add_instr [NS, name]
      block.add_instr [DEF_MEMBER, name, 'default']
      ns_reg = copy_and_return_reg block

      # Invoke block immediately and remove it to reduce memory usage
      block.add_instr [DEFAULT, body_block.id]
      block.add_instr [CALL, 'default', {
        'inherit_scope' => false,
        'self_reg'      => ns_reg,
      }]

      # Return the class
      block.add_instr [COPY, ns_reg, 'default']
    end

    # Process source["source"]
    # Load code from location (compie first if necessary)
    #   Call default block of loaded code
    #   Store root namespace of loaded code in default register
    # Define members in current context
    def compile_import block, source
      compile_ block, source['source']

      mappings = source['mappings']
      if mappings.size > 0
        loaded_context_reg = new_reg
        block.add_instr [LOAD, 'default', loaded_context_reg]

        mappings.each do |name, value|
          block.add_instr [GET_CHILD_MEMBER, loaded_context_reg, name]
          block.add_instr [DEF_MEMBER, value, 'default']
        end
      else
        block.add_instr [LOAD, 'default', nil]
      end
    end

    def compile_string block, source
      reg = new_reg
      block.add_instr [WRITE, reg, source.type]
      source.data.each do |item|
        compile_ block, item
        block.add_instr [CONCAT, reg, 'default']
      end
      block.add_instr [COPY, reg, 'default']
    end

    def compile_literal block, source
      block.add_instr [DEFAULT, source]
    end

    def compile_print block, source
      source.data.each do |item|
        compile_ block, source.data[0]
        block.add_instr [PRINT, 'default', false]
      end
      block.add_instr [DEFAULT, nil]
    end

    def compile_invoke block, source
      target, method, *args = source.data

      compile_ block, target
      target_reg = copy_and_return_reg block

      compile_ block, method
      method_reg = copy_and_return_reg block

      compile_array block, args

      block.add_instr [CALL_NATIVE_DYNAMIC, target_reg, method_reg, 'default']
    end

    def compile_assert block, source
      expr = source.data[0]
      compile_ block, expr
      jump = block.add_instr [JUMP_IF_TRUE, nil]

      if source.data.length > 1
        compile_ block, source.data[1]
      else
        block.add_instr [DEFAULT, "AssertionError: #{expr}"]
      end
      block.add_instr [THROW, 'default']

      jump[1] = block.length
    end

    def compile_unknown block, source
      block.add_instr [TODO, source.inspect]
    end

    def is_literal? source
      if source.is_a? Array
        source.all? {|item| is_literal?(item) }
      elsif source.is_a? Hash
        result = true
        source.each do |key, value|
          if not is_literal? value
            result = false
            break
          end
        end
        result
      elsif source.is_a? Gene::Types::Base
        false
      elsif source.is_a? Gene::Types::Symbol
        false
      else
        true
      end
    end

    def copy_and_return_reg block
      reg = new_reg
      block.add_instr [COPY, 'default', reg]
      reg
    end

    def new_reg
      if not @used_registers
        @used_registers = []
      end

      # Prevent collision - cache all registers assigned so far and check existance
      reg = nil
      while true
        reg = "R#{rand(100000)}"
        if not @used_registers.include? reg
          break
        end
      end
      reg
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

    def initialize primary_block = nil
      @blocks = {}
      if primary_block
        self.primary_block = primary_block
      end
    end

    def add_block block
      @blocks[block.id] = block
    end

    def get_block id
      @blocks[id]
    end

    def primary_block= block
      add_block block
      @primary_block = block
    end

    def to_s indent = nil
      s = "\n(CompiledModule"
      @blocks.each do |id, block|
        if id == @primary_block.id
          id += "__primary"
        else
          id += "__#{block.name}"
        end
        s << "\n  ^#{id} " << block.to_s('    ')
      end
      s << "\n)"

      if indent
        s.gsub! "\n", "\n#{indent}"
      end

      s
    end
    alias inspect to_s

    def to_json
      {
        type:   "CompiledModule",
        blocks: blocks.values,
      }.to_json
    end

    def self.from_json json
      mod = new
      json['blocks'].each do |block_json|
        block = CompiledBlock.from_json block_json
        if block.is_default?
          mod.primary_block = block
        else
          mod.add_block block
        end
      end
      mod
    end
  end

  class CompiledBlock
    attr_accessor :id
    attr_accessor :name
    attr_writer :is_default
    attr_reader :instructions

    def initialize instructions = []
      @id           = SecureRandom.uuid
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

    def to_json options = {}
      hash = {type: "CompiledBlock"}
    if name
        hash[:name] = name
      end
      if is_default?
        hash[:default] = true
      end
      hash[:id] = id
      hash[:instructions] = instructions
      hash.to_json
    end

    def self.from_json json
      block = new json['instructions']
      block.id         = json['id']
      block.name       = json['name']
      block.is_default = json['default']
      block
    end
  end
end