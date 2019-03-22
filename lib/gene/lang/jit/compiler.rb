require 'securerandom'
require 'json'

module Gene::Lang::Jit
  class Compiler
    include Utils

    VERSION = "1.0"

    TEMPLATE_MODE = 'template_mode'
    RENDER_MODE   = 'render_mode'

    def initialize
    end

    def parse_and_compile string
      parsed = Gene::Parser.parse string
      compile parsed
    end

    # Options:
    #   skip_init: do not add INIT instruction
    #   mode = render: (%% ...), (%= ...)
    #   mode = template: (:: ...)
    # return CompiledModule
    def compile source, options = {}
      primary_block = CompiledBlock.new []
      primary_block.is_default = true
      if not options[:skip_init]
        primary_block.add_instr [INIT]
      end
      @mod = CompiledModule.new primary_block
      compile_ primary_block, source, options
      primary_block.add_instr [CALL_END]
      @mod
    end

    def compile_ block, source, options
      source = process_decorators source

      if source.is_a? Gene::Types::Base
        compile_object block, source, options
      elsif source.is_a? Gene::Types::Symbol
        compile_symbol block, source, options
      elsif source.is_a? Gene::Lang::Statements
        compile_statements block, source, options
      elsif source.is_a? Gene::Types::Stream
        compile_stream block, source, options
      elsif source.is_a? Array
        compile_array block, source, options
      elsif source.is_a? Hash
        compile_hash block, source, options
      else
        compile_literal block, source, options
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

    def compile_object block, source, options
      if not options[TEMPLATE_MODE]
        source = Gene::Lang::Transformer.new.call(source)
      end

      op = source.data[0]

      if options[TEMPLATE_MODE]
        compile_ block, source.type, options
        type_reg = copy_and_return_reg block

        compile_ block, source.properties, options
        props_reg = copy_and_return_reg block

        compile_ block, source.data, options
        data_reg = 'default'

        block.add_instr [CREATE_OBJ, type_reg, props_reg, data_reg]

      elsif op.is_a? Gene::Types::Symbol and op.name[0] == '.'
        compile_method_invocation block, source, options

      elsif BINARY_OPS.include?(op)
        if [EQ, LT, LE, GT, GE].include? op
          compile_ block, source.type, options
          first_reg  = copy_and_return_reg block

          compile_ block, source.data[1], options
          block.add_instr [BINARY, first_reg, op.to_s, 'default']

        elsif [PLUS, MINUS, MULTI, DIV].include? op
          compile_ block, source.type, options
          first_reg  = copy_and_return_reg block

          compile_ block, source.data[1], options
          block.add_instr [BINARY, first_reg, op.to_s, 'default']

        elsif op == AND
          compile_ block, source.type, options
          # Skip evaluating second expression if false
          jump = block.add_instr [JUMP_IF_FALSE, nil]
          compile_ block, source.data[1], options
          jump[1] = block.length

        elsif op == OR
          compile_ block, source.type, options
          # Skip evaluating second expression if false
          jump = block.add_instr [JUMP_IF_TRUE, nil]
          compile_ block, source.data[1], options
          jump[1] = block.length

        elsif op == ASSIGN
          compile_ block, source.data[1], options
          target = source.type.to_s
          if target[0] == '@'
            value_reg = copy_and_return_reg block
            block.add_instr [CALL_NATIVE, 'context', 'self']
            block.add_instr [SET, 'default', target[1..-1], value_reg]
          else
            block.add_instr [SET_MEMBER, target, 'default']
          end

        elsif [PLUS_EQ, MINUS_EQ, MULTI_EQ, DIV_EQ].include? op
          compile_ block, source.data[1], options
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
          compile_unknown block, source, options
        end

      elsif source.type.is_a? Gene::Types::Symbol
        type = source.type.to_s

        if type[0] == "."
          compile_short_method_invocation block, source, options
        elsif type == "#QUOTE"
          compile_template block, source.data[0], options
        elsif type == "%%" or type == "%="
          compile_render_obj block, source, options
        elsif type == "var"
          compile_var block, source, options
        elsif type == "undef"
          compile_undef block, source, options
        elsif type == "do"
          compile_do block, source, options
        elsif type == "if"
          compile_if block, source, options
        elsif type == "loop"
          compile_loop block, source, options
        elsif type == "for"
          compile_for block, source, options
        elsif type == "fn"
          compile_fn block, source, options
        elsif type == "class"
          compile_class block, source, options
        elsif type == "module"
          compile_module block, source, options
        elsif type == "method"
          compile_method block, source, options
        elsif type == "new"
          compile_new block, source, options
        elsif type == "init"
          compile_init block, source, options
        elsif type == "super"
          compile_super block, source, options
        elsif type == "ns"
          compile_namespace block, source, options
        elsif type == "import"
          compile_import block, source, options
        elsif type == "return"
          compile_return block, source, options
        elsif type == "break"
          compile_break block, source, options
        elsif type == "!"
          compile_invert block, source, options
        elsif type == "eval"
          compile_eval block, source, options
        elsif type == "render"
          compile_render block, source, options
        elsif type == "try"
          compile_try block, source, options
        elsif type == "throw"
          compile_throw block, source, options
        elsif type == "label"
          compile_label block, source, options
        elsif type == "goto"
          compile_goto block, source, options
        elsif type == "callcc"
          compile_callcc block, source, options
        elsif type == "yield"
          compile_yield block, source, options
        elsif type == "assert" || type == "assert_not"
          compile_assert block, source, options
        elsif type == "print" or type == "println"
          compile_print block, source, options
        elsif type.is_a?(String) && type =~ /^\$.*/
          compile_internal block, source, options
        else
          compile_invocation block, source, options
        end

      elsif source.type.is_a? String
        compile_string block, source, options

      elsif source.type.is_a? Gene::Types::Base
        compile_invocation block, source, options

      elsif source.type.is_a? Gene::Lang::Jit::Function
        compile_invocation block, source, options

      else
        compile_unknown block, source, options
        # compile_ block, source.type
        # if eval_arguments is true, evaluate arguments
        # invoke function with rest as arguments
      end
    end

    def compile_var block, source, options
      name = source.data.first.to_s
      if name.include? '/'
        namespace, _, name = name.rpartition '/'
        compile_symbol block, namespace, options
        ns_reg = copy_and_return_reg block
        if source.data.length == 1
          block.add_instr [DEF_CHILD_MEMBER, ns_reg, name, nil]
        else
          compile_ block, source.data[1], options
          block.add_instr [DEF_CHILD_MEMBER, ns_reg, name, 'default']
        end

      elsif source.data.length == 1
        block.add_instr [DEF_MEMBER, name, nil, {'type' => 'scope'}]
      else
        compile_ block, source.data[1], options
        block.add_instr [DEF_MEMBER, name, 'default', {'type' => 'scope'}]
      end
    end

    def compile_undef block, source, options
      name = source.data.first.to_s
      block.add_instr [UNDEF_MEMBER, name]
    end

    def compile_do block, source, options
      compile_statements block, source.data, options
    end

    def compile_if block, source, options
      compile_ block, source['cond'], options

      jump1 = block.add_instr [JUMP_IF_FALSE, nil]

      compile_ block, source['then'], options
      jump2 = block.add_instr [JUMP, nil]

      jump1[1] = block.length

      compile_ block, source['else'], options

      jump2[1] = block.length
    end

    def compile_loop block, source, options
      start_pos = block.length
      compile_statements block, source.data, options
      block.add_instr [JUMP, start_pos]
      start_pos.upto(block.length - 1) do |i|
        instr = block[i]
        if instr[0] == JUMP and instr[1] < 0
          instr[1] = block.length
        end
      end
    end

    def compile_for block, source, options
      init, cond, update, *rest = source.data

      compile_ block, init, options

      cond_pos = block.length
      compile_ block, cond, options
      cond_jump = block.add_instr [JUMP_IF_FALSE, nil]

      compile_ block, Gene::Lang::Statements.new(rest), options

      compile_ block, update, options
      block.add_instr [JUMP, cond_pos]

      cond_jump[1] = block.length
    end

    def compile_break block, source, options
      block.add_instr [JUMP, -1]
    end

    # Save registers, block, position to register
    def compile_label block, source, options
      block.add_instr [LABEL, source.data[0].to_s]
    end

    def compile_goto block, source, options
      block.add_instr [GOTO, source.data[0].to_s]
    end

    def compile_callcc block, source, options
      compile_ block, source.data[0], options
      block.add_instr [CALLCC, 'default']
    end

    def compile_yield block, source, options
      compile_ block, source.data[0], options
      block.add_instr [YIELD, 'default']
    end

    def compile_fn block, source, options
      name = source['name'].to_s
      short_name = get_short_name name

      # Compile function body as a block
      # Function default args are evaluated in the block as well
      body_block      = CompiledBlock.new
      body_block.name = short_name

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

      compile_ body_block, source['body'], options
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a function object and store in namespace/scope
      block.add_instr [FN, short_name, body_block.id, source['options']]

      compile_name block, name, 'default', {'type' => 'namespace'}
    end

    # Options: type = namespace or scope
    def compile_name block, name, value_reg, options
      if name.include? '/'
        if value_reg == 'default'
          value_reg = copy_and_return_reg block
        end

        first, *rest, last = name.split("/")
        if first == 'global'
          block.add_instr [GLOBAL]
        else
          block.add_instr [GET_MEMBER, first]
        end

        rest.each do |item|
          block.add_instr [GET_CHILD_MEMBER, 'default', item]
        end

        block.add_instr [DEF_CHILD_MEMBER, 'default', last, value_reg]
      else
        block.add_instr [DEF_MEMBER, name, 'default', options]
      end
    end

    def compile_internal block, source, options
      instr_type = source.type.to_s[1..-1]

      if source.data.empty?
        block.add_instr [instr_type]
      else
        compile_ block, source.data, options
        block.add_instr [instr_type, 'default']
      end
    end

    def compile_invocation block, source, options
      compile_ block, source.type, options

      fn_reg = copy_and_return_reg block

      args_reg = compile_args block, source, options

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
    def compile_template block, source, options
      options = options.clone
      options[TEMPLATE_MODE] = true
      compile_ block, source, options
    end

    def compile_return block, source, options
      compile_ block, source.data[0], options
      block.add_instr [CALL_END]
    end

    def compile_invert block, source, options
      compile_ block, source.data[0], options
      block.add_instr [INVERT, 'default']
    end

    # Arguments are compiled and processed first
    # Results are treated as statements
    # Statements are compiled to a CompiledModule
    # The default block will be invoked
    def compile_eval block, source, options
      compile_array block, source.data, options
      block.add_instr [COMPILE, 'default']
      block.add_instr [RUN, 'default']
    end

    # Process %x and (%x ...) inside template
    # Iterate through data
    # Compile with {mode: render} option
    def compile_render block, source, options
      options = options.clone
      options[RENDER_MODE] = true
      source.data.each do |item|
        compile_ block, item, options
      end
    end

    def compile_render_obj block, source, options
      if options[RENDER_MODE]
        source.data.each do |item|
          compile_ block, item, options
        end
      else
        options = options.clone
        options[TEMPLATE_MODE] = true
        compile_ block, source, options
      end
    end

    def compile_symbol block, source, options
      if options[RENDER_MODE]
        str = source.to_s
        if str[0] == '%'
          compile_ block, Gene::Types::Symbol.new(str[1..-1]), options
          return
        end
      end

      if options[TEMPLATE_MODE]
        block.add_instr [SYMBOL, source.to_s]
      else
        str = source.to_s
        if str == '__'
          block.add_instr [LAST_RESULT]
        elsif str[0] == '@'
          block.add_instr [CALL_NATIVE, 'context', 'self']
          block.add_instr [GET, 'default', str[1..-1], 'default']
        elsif str[0] == ':'
          block.add_instr [SYMBOL, str[1..-1]]
        elsif str[0] == '%'
          block.add_instr [SYMBOL, str]
        elsif str == "self"
          block.add_instr [CALL_NATIVE, 'context', 'self']
        elsif str == "ARGV"
          block.add_instr [ARGS]
        else
          first, *rest = str.split '/'
          if first == 'global'
            block.add_instr [GLOBAL]
          else
            block.add_instr [GET_MEMBER, first]
          end
          rest.each do |item|
            block.add_instr [GET_CHILD_MEMBER, 'default', item]
          end
        end
      end
    end

    def compile_statements block, source, options
      source.each do |item|
        compile_ block, item, options
      end
    end

    def compile_stream block, source, options
      if options[TEMPLATE_MODE]
        block.add_instr [STREAM]
        reg = copy_and_return_reg block

        source.each_with_index do |value, index|
          if is_literal? value
            result[index] = value
          else
            compile_ block, value, options
            block.add_instr [SET, reg, index, 'default']
          end
        end

        block.add_instr [COPY, reg, 'default']
      else
        source.each do |item|
          compile_ block, item, options
        end
      end
    end

    def compile_array block, source, options
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

    def compile_hash block, source, options
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
            compile_ block, value, options
            block.add_instr [SET, reg, key, 'default']
          end
        end

        block.add_instr [COPY, reg, 'default']
      end
    end

    def compile_class block, source, options
      name        = source['name'].to_s
      body        = source['body']
      super_class = source['super_class']

      # Compile body as a block
      body_block      = CompiledBlock.new
      body_block.name = name

      compile_ body_block, body, options
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a class object and store in namespace/scope
      block.add_instr [CLASS, name]
      block.add_instr [DEF_MEMBER, name, 'default', {'type' => 'namespace'}]

      class_reg = copy_and_return_reg block

      if super_class
        compile_ block, super_class, options
        block.add_instr [CALL_NATIVE, class_reg, 'parent_class=', 'default']
      end

      # Invoke block immediately and remove it to reduce memory usage
      block.add_instr [DEFAULT, body_block.id]
      block.add_instr [CALL, 'default', {
        'inherit_scope' => false,
        'self_reg'      => class_reg,
        'namespace_reg' => class_reg,
      }]

      # Return the class
      block.add_instr [COPY, class_reg, 'default']
    end

    def compile_module block, source, options
      name = source.data[0].to_s
      body = source.data[1..-1]

      # Compile body as a block
      body_block      = CompiledBlock.new
      body_block.name = name

      compile_ body_block, body, options
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a class object and store in namespace/scope
      block.add_instr [MODULE, name]
      block.add_instr [DEF_MEMBER, name, 'default', {'type' => 'namespace'}]
      class_reg = copy_and_return_reg block

      # Invoke block immediately and remove it to reduce memory usage
      block.add_instr [DEFAULT, body_block.id]
      block.add_instr [CALL, 'default', {
        'inherit_scope' => false,
        'self_reg'      => class_reg,
        'namespace_reg' => class_reg,
      }]

      # Return the class
      block.add_instr [COPY, class_reg, 'default']
    end

    # Compile method body as a block
    # Default args are evaluated in the block as well
    def compile_method block, source, options
      body_block      = CompiledBlock.new
      body_block.name = source['name']

      # Arguments & default values
      args = source['args']
      args.data_matchers.each do |matcher|
        body_block.add_instr [GET, 'args', matcher.index, 'default']
        body_block.add_instr [DEF_MEMBER, matcher.name, 'default']
      end

      compile_ body_block, source['body'], options
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a function object and store in namespace/scope
      block.add_instr [METHOD, source['name'], body_block.id]
    end

    # Compile method body as a block
    # Default args are evaluated in the block as well
    def compile_init block, source, options
      method_name = 'init'

      body_block      = CompiledBlock.new
      body_block.name = method_name

      # Arguments & default values
      args = Gene::Lang::Matcher.from_array source.data.first
      args.data_matchers.each do |matcher|
        body_block.add_instr [GET, 'args', matcher.index, 'default']
        body_block.add_instr [DEF_MEMBER, matcher.name, 'default']
      end

      compile_ body_block, source.data[1..-1], options
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a function object and store in namespace/scope
      block.add_instr [METHOD, method_name, body_block.id]
    end

    def compile_new block, source, options
      compile_ block, source.data.first, options
      class_reg = copy_and_return_reg block

      args_reg = compile_args block, source, options, true

      block.add_instr [NEW, class_reg, args_reg]
    end

    # Get class of object
    # Get class hierarchy
    # Get method from hierarchy
    # If method's eval_arguments option is false, do not eval arguments (same as function)
    # Call method with self object, arguments, class, hierarchy (is useful when super is invoked)
    def compile_method_invocation block, source, options
      compile_ block, source.type, options

      self_reg = copy_and_return_reg block

      block.add_instr [GET_CLASS, self_reg]

      # Create a hierarchy for class stored in default register
      block.add_instr [CREATE_INHERITANCE_HIERARCHY, 'default']

      hierarchy_reg = copy_and_return_reg block

      method_name    = source.data.first.to_s[1..-1]
      args_reg       = compile_args block, source, options, true

      block.add_instr [CALL_METHOD, self_reg, method_name, args_reg, hierarchy_reg]
    end

    # Get class of object
    # Get class hierarchy
    # Get method from hierarchy
    # If method's eval_arguments option is false, do not eval arguments (same as function)
    # Call method with self object, arguments, class, hierarchy (is useful when super is invoked)
    def compile_short_method_invocation block, source, options
      block.add_instr [CALL_NATIVE, 'context', 'self']

      self_reg = copy_and_return_reg block

      block.add_instr [GET_CLASS, self_reg]

      # Create a hierarchy for class stored in default register
      block.add_instr [CREATE_INHERITANCE_HIERARCHY, 'default']

      hierarchy_reg = copy_and_return_reg block

      method_name   = source.type.to_s[1..-1]
      args_reg      = compile_args block, source, options

      block.add_instr [CALL_METHOD, self_reg, method_name, args_reg, hierarchy_reg]
    end

    # Get hierarchy from hierarchy register (if not found, throw error?)
    def compile_super block, source, options
      hierarchy_reg   = 'hierarchy'
      # Advance the hierarch search object
      block.add_instr [CALL_NATIVE, hierarchy_reg, 'next']

      # Get method name
      block.add_instr [CALL_NATIVE, 'method', 'name']
      method_name_reg = copy_and_return_reg block

      # TODO: (super!) will re-use the arguments
      args_reg = compile_args block, source, options, true

      block.add_instr [CALL_NATIVE, 'context', 'self']

      block.add_instr [CALL_DYNAMIC_METHOD, 'default', method_name_reg, args_reg, hierarchy_reg]
    end

    # Compile args
    # Save to a register
    # @return the regiser address
    def compile_args block, source, options, is_method = false
      args_data = is_method ? source.data[1..-1] : source.data

      if not args_data or args_data.length == 0
        return
      elsif args_data and not is_literal?(args_data)
        compile_ block, args_data, options
        data_reg = copy_and_return_reg block
      else
        data_reg = new_reg
        block.add_instr [WRITE, data_reg, args_data]
      end

      data_reg
    end

    def get_short_name name
      if name.index('/')
        name[(name.index('/') + 1) .. -1]
      else
        name
      end
    end

    def compile_namespace block, source, options
      name = source.data[0].to_s
      body = source.data[1..-1]

      short_name = get_short_name name

      # Compile body as a block
      body_block      = CompiledBlock.new
      body_block.name = short_name

      compile_ body_block, body, options
      body_block.add_instr [CALL_END]

      @mod.add_block body_block

      # Create a class object and store in namespace/scope
      block.add_instr [NS, short_name]
      ns_reg = copy_and_return_reg block
      compile_name block, name, ns_reg, {'type' => 'namespace'}

      # Invoke block immediately and remove it to reduce memory usage
      block.add_instr [DEFAULT, body_block.id]
      block.add_instr [CALL, 'default', {
        'inherit_scope' => false,
        'self_reg'      => ns_reg,
        'namespace_reg' => ns_reg,
      }]

      # Return the class
      block.add_instr [COPY, ns_reg, 'default']
    end

    # Process source["source"]
    # Load code from location (compie first if necessary)
    #   Call default block of loaded code
    #   Store root namespace of loaded code in default register
    # Define members in current context
    def compile_import block, source, options
      compile_ block, source['source'], options

      mappings = source['mappings']
      if mappings.size > 0
        loaded_context_reg = new_reg
        block.add_instr [LOAD, 'default', loaded_context_reg]

        mappings.each do |name, value|
          block.add_instr [GET_CHILD_MEMBER, loaded_context_reg, name]
          block.add_instr [DEF_MEMBER, value, 'default', {'type' => 'namespace'}]
        end
      else
        block.add_instr [LOAD, 'default', nil]
      end
    end

    def compile_string block, source, options
      reg = new_reg
      block.add_instr [WRITE, reg, source.type]
      source.data.each do |item|
        compile_ block, item, options
        block.add_instr [CONCAT, reg, 'default']
      end
      block.add_instr [COPY, reg, 'default']
    end

    def compile_literal block, source, options
      block.add_instr [DEFAULT, source]
    end

    def compile_print block, source, options
      source.data.each do |item|
        compile_ block, item, options
        block.add_instr [PRINT, 'default', false]
      end
      if source.type.to_s == 'println'
        block.add_instr [PRINT, nil, true]
      end
      block.add_instr [DEFAULT, nil]
    end

    def compile_try block, source, options
      catches = block.add_instr [ADD_ERROR_HANDLERS,  []]
      jumpes = []

      compile_ block, source['try'], options
      jumpes << block.add_instr([JUMP, nil])

      source['catch'].each do |pair|
        catches[1] << block.length
        exception, logic = pair
        compile_ block, exception, options
        block.add_instr [CHECK_EXCEPTION]

        compile_ block, logic, options
        block.add_instr [CLEAR_EXCEPTION]

        jumpes << block.add_instr([JUMP, nil])
      end

      # Jump to before ensure block
      jumpes.each do |jump|
        jump[1] = block.length
      end

      # TODO: ensure

      #block.add_instr [COMMENT, id, 'end']
    end

    def compile_throw block, source, options
      compile_ block, source.data[0], options
      block.add_instr [THROW, 'default']
    end

    def compile_assert block, source, options
      expr = source.data[0]
      compile_ block, expr, options

      is_assert_not = source.type.name == 'assert_not'
      instr_type = is_assert_not ? JUMP_IF_FALSE : JUMP_IF_TRUE
      jump = block.add_instr [instr_type, nil]

      if source.data.length > 1
        compile_ block, source.data[1], options
      else
        block.add_instr [DEFAULT, "AssertionError: #{expr}"]
      end
      block.add_instr [THROW, 'default']

      jump[1] = block.length
    end

    def compile_unknown block, source, options
      raise "Not implemented: #{source.inspect}"
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
    attr_reader :id
    attr_reader :version
    # Special attributes that may help VM when executes this module
    attr_reader :metadata
    attr_reader :blocks
    attr_reader :primary_block

    def initialize primary_block = nil
      @id     = SecureRandom.uuid
      @blocks = {}
      if primary_block
        add_block primary_block
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
    attr_reader :id
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
        s << "#{i.to_s.rjust(3)}: #{instr[0]} #{instr[1..-1].to_s.gsub(/^\[/, '').gsub(/\]$/, '').gsub(/, /, ' ')}"
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
