class Gene::Lang::Compiler
  def initialize
    init_handlers
  end

  def init_handlers
    @handlers = Gene::Handlers::ComboHandler.new
    @handlers.add 100, FunctionHandler.new
    @handlers.add 100, DefaultHandler.new
  end

  def parse_and_process input
    parsed = Gene::Parser.parse input
    # var $root_context = $application.create_root_context();
    # (function($context){
    #   var $result;
    #   $result = $context.var("a", 1);
    #   return $result;
    # })($root_context);
    Root.new(self) {
      stmts << var('$root_context',
        chain(ref('$application'), invoke('create_root_context'))
      )
      stmts << invoke(
        fnx(['$context']) {
          stmts << var('$result')
          if parsed.is_a? Gene::Types::Stream
            stmts.concat Gene::Lang::Compiler.compile_stmts(self, parsed)
          else
            stmts << assign(ref('$result'), process(parsed))
          end
          stmts << ret(ref('$result'))
        },
        ref('$root_context')
      )
    }
  end

  def process context, data
    result = @handlers.call context, data
  end

  PLACEHOLDER = Gene::Types::Symbol.new('_')
  %W(
    NS
    CLASS PROP METHOD NEW INIT CAST
    MODULE INCLUDE
    EXTEND SUPER
    SELF WITH
    SCOPE
    FN FNX FNXX BIND
    RETURN
    CALL DO
    VAR
    ASPECT BEFORE AFTER WHEN CONTINUE
    IMPORT EXPORT FROM
    PUBLIC PRIVATE
    IF IF_NOT ELSE
    FOR LOOP
    THROW CATCH
    BREAK
    PRINT PRINTLN
    ASSERT DEBUG
    NOOP
  ).each do |name|
    const_set name, Gene::Types::Symbol.new("#{name.downcase.gsub('_', '-')}")
  end

  BINARY_OPERATORS = [
    Gene::Types::Symbol.new('=='),
    Gene::Types::Symbol.new('!='),
    Gene::Types::Symbol.new('>'),
    Gene::Types::Symbol.new('>='),
    Gene::Types::Symbol.new('<'),
    Gene::Types::Symbol.new('<='),

    Gene::Types::Symbol.new('+'),
    Gene::Types::Symbol.new('-'),
    Gene::Types::Symbol.new('*'),
    Gene::Types::Symbol.new('/'),

    Gene::Types::Symbol.new('&&'),
    Gene::Types::Symbol.new('||'),
  ]

  class FunctionHandler
    def call context, data
      if FN === data
        name = data.data[0].to_s
        args = data.data[1].map {|arg| arg.to_s }
        body = data.data[2..-1]
        context.eval {
          chain(
            ref('$context'),
            invoke(
              ref('set_member'),
              name,
              new(chain(ref('Gene'), invoke(ref('Func'), name, args, fnx('$context') {
                stmts << var('$result')
                stmts.concat Gene::Lang::Compiler.compile_stmts(self, body)
                stmts << ret(ref('$result'))
              })))
            )
          )
        }
      else
        Gene::NOT_HANDLED
      end
    end
  end

  class DefaultHandler
    def call context, data
      if data.is_a? Gene::Types::Base
        if VAR === data
          if data.data.length == 1
            # "$context.var(\"#{data.data[0]}\");"
            context.eval { chain(ref('$context'), invoke('var', data.data[0].to_s)) }
          else
            # "$context.var(\"#{data.data[0]}\", #{context.process(data.data[1])});"
            context.eval { chain(ref('$context'), invoke('var', data.data[0].to_s, process(data.data[1]))) }
          end
        elsif Gene::Types::Symbol.new('+=') == data.data[0]
          left  = data.type.to_s
          right = data.data[1]
          # $context.set_member(<left>, $context.get_member(<left>) + process(<right>))
          context.eval {
            chain(
              ref('$context'),
              invoke('set_member', left, binary(chain(ref('$context'), invoke('get_member', left)), '+', process(right)))
            )
          }
        elsif BINARY_OPERATORS.include?(data.data[0])
          op    = data.data[0].name
          left  = context.process(data.type)
          right = context.process(data.data[1])
          # "#{left} #{op} #{right}"
          context.eval { binary(process(data.type), op, process(data.data[1])) }
        elsif FOR === data
          init    = context.process(data.data[0])
          cond    = context.process(data.data[1])
          update  = context.process(data.data[2])
          stmts   = data.data[3..-1].map do |item|
            context.process(item)
          end
          context.for(init, cond, update, stmts)
        elsif BREAK === data
          context.break_()
        elsif IF === data
          cond = context.process(data.data[0])
          else_index = data.data.index(ELSE)
          if else_index
            then_logic = data.data[1..else_index - 1]
            else_logic = data.data[else_index + 1 .. -1]
            context.eval {
              if_(cond,
                then_logic.map {|stmt| process(stmt) },
                else_logic.map {|stmt| process(stmt) },
              )
            }
          else
            then_logic = data.data[1..-1]
          end
        elsif ASSERT === data
          args = data.data[0..1].map do |arg|
            context.process arg
          end
          context.eval { chain(ref('Gene'), invoke(context.ref('assert'), *args)) }
        else # Defaults to function invocations
          context.eval {
            chain(
              ref('$context'),
              invoke(ref('get_member'), data.type.to_s),
              # TODO: support evaluating arguments in function context (if eval_arguments is set to false)
              # One way is to use invoke_with_callback(function($context){...}) if any argument has to be evaluated
              invoke(ref('invoke'), obj(context: ref('$context'), arguments: data.data.map {|arg| context.process(arg) }))
             )
          }
        end
      # elsif data.is_a?(::Array) and not data.is_a?(Gene::Lang::Array)
      #   result = Gene::Lang::Array.new
      #   data.each do |item|
      #     result.push context.process(item)
      #   end
      #   result
      # elsif data.is_a?(Hash) and not data.is_a?(Gene::Lang::Hash)
      #   result = Gene::Lang::Hash.new
      #   data.each do |key, value|
      #     result[key] = context.process value
      #   end
      #   result
      # elsif data == PLACEHOLDER or data == NOOP
      #   Gene::UNDEFINED
      # elsif data == BREAK
      #   Gene::Lang::BreakValue.new
      # elsif data == RETURN
      #   result = Gene::Lang::ReturnValue.new
      #   result
      # elsif data == APPLICATION
      #   context.application
      # elsif data == CONTEXT
      #   context
      # elsif data == GLOBAL
      #   context.application.global_namespace
      # elsif data == CURRENT_SCOPE
      #   context.scope
      # elsif data == SELF
      #   context.self
      elsif data.is_a? Gene::Types::Symbol
        # "$context.get_member('#{data}')"
        context.eval { chain(ref('$context'), invoke('get_member', data.to_s)) }
      elsif data.is_a? Hash
        context.obj(data)
      else
        # literals
        data
      end
    end
  end

  class Base
    attr_accessor :parent

    def initialize parent
      @parent = parent
    end

    def is_root?
      !parent
    end

    def root
      if is_root?
        self
      else
        @root ||= @parent.root
      end
    end

    def process data
      root.compiler.process self, data
    end

    def inspect
      to_s
    end

    def stmts_to_s
      s = ""
      if @stmts
        @stmts.each do |stmt|
          s << stmt.to_s << ";\n"
        end
      end
      s
    end

    # Helper methods
    def var name, value = Gene::UNDEFINED
      Variable.new(self, name, value)
    end

    def ref name
      Reference.new(self, name)
    end

    def new rest
      New.new(self, rest)
    end

    def fn name, args, &block
      Function.new(self, name, args, &block)
    end

    def fnx args, &block
      Function.new(self, '', args, &block)
    end

    def fnxx &block
      Function.new(self, '', [], &block)
    end

    def for init, cond, update, stmts
      For.new(self, init, cond, update, stmts)
    end

    def chain *exprs
      ChainedInvocation.new(self, exprs)
    end

    def invoke target, *args
      Invocation.new(self, target, args)
    end

    def binary left, op, right
      BinaryExpr.new(self, left, op, right)
    end

    def assign target, value
      Assignment.new(self, target, value)
    end

    def ret value
      Return.new(self, value)
    end

    def eval &block
      instance_eval &block
    end

    def break_
      Break.new(self)
    end

    def if_ cond, logic, else_logic
      If.new(self, cond, logic, else_logic)
    end

    def obj data
      Obj.new(self, data)
    end
  end

  class Root < Base
    attr_accessor :compiler, :stmts

    def initialize compiler, &block
      @compiler = compiler
      @stmts    = []

      if block_given?
        instance_eval &block
      end
    end

    def to_s
      s = ""
      s << stmts_to_s
      s
    end
  end

  class Function < Base
    attr_accessor :name, :args, :stmts

    def initialize parent, name, args, &block
      super(parent)
      @name  = name
      @args  = args.is_a?(Array) ? args : [args]
      @stmts = []

      if block_given?
        instance_eval &block
      end
    end

    def to_s
      s = "function"
      if not name.to_s.empty?
        s << " " << name
      end
      s << "(" << args.join(", ") << "){\n"
      s << stmts_to_s
      s << "}\n"
      s
    end
  end

  class If < Base
    attr_accessor :cond, :logic, :else_logic
    attr_accessor :else_ifs # pair of condition and logic

    def initialize parent, cond, logic, else_logic
      super(parent)
      @cond       = cond
      @logic      = logic
      @else_ifs   = []
      @else_logic = else_logic
    end

    def to_s
      s = "if ("
      s << cond.to_s << ") {\n"
      logic.each do |stmt|
        s << stmt.to_s << ";\n"
      end
      if else_logic and else_logic.size > 0
        s << "} else {\n"
        else_logic.each do |stmt|
          s << stmt.to_s << ";\n"
        end
      end
      s << "}"
      s << "\n"
    end
  end

  class For < Base
    attr_accessor :init, :cond, :update, :stmts

    def initialize parent, init, cond, update, stmts
      super(parent)
      @init   = init
      @cond   = cond
      @update = update
      @stmts  = stmts
    end

    def to_s
      s = ""
      s << "for(#{init}; #{cond}; #{update}) {\n"
      s << stmts_to_s
      s << "}\n"
      s
    end
  end

  class Variable < Base
    attr_accessor :name, :value

    def initialize parent, name, value = Gene::UNDEFINED
      super(parent)
      @name  = name
      @value = value
    end

    def initialized?
      @value != Gene::UNDEFINED
    end

    def to_s
      s = ""
      s << "var " << name.to_s
      if initialized?
        s << " = " << value.to_s
      end
      s
    end
  end

  class Reference < Base
    attr_accessor :name

    def initialize parent, name
      super(parent)
      @name = name
    end

    def to_s
      name.to_s
    end
  end

  class Assignment < Base
    attr_accessor :target, :value

    def initialize parent, target, value
      super(parent)
      @target = target
      @value  = value
    end

    def to_s
      "#{target} = #{value}"
    end
  end

  class Invocation < Base
    attr_accessor :target, :args

    def initialize parent, target, args
      super(parent)
      @target = target
      @args   = args
    end

    def to_s
      s = ""
      if target.is_a? Function
        s << "(" << target.to_s << ")"
      else
        s << target.to_s
      end
      s << "(" << args.map(&:inspect).join(', ') << ")"
      s
    end
  end

  # a.b.c(1).d(2, 3)
  # a().b(1).c
  class ChainedInvocation < Base
    attr_accessor :invocations

    def initialize parent, invocations
      super(parent)
      @invocations = invocations
    end

    def to_s
      s = ""
      s << @invocations.map(&:to_s).join(".")
      s
    end
  end

  class BinaryExpr < Base
    attr_accessor :left, :op, :right

    def initialize parent, left, op, right
      super(parent)
      @left  = left
      @op    = op
      @right = right
    end

    def to_s
      "(#{left.inspect} #{op} #{right.inspect})"
    end
  end

  class Return < Base
    attr_accessor :value

    def initialize parent, value
      super(parent)
      self.value = value
    end

    def to_s
      "return #{value}"
    end
  end

  class Break < Base
    def initialize parent
      super(parent)
    end

    def to_s
      "break"
    end
  end

  class New < Base
    attr_accessor :rest

    def initialize parent, rest
      super(parent)
      self.rest = rest
    end

    def to_s
      "new #{rest}"
    end
  end

  class Obj < Base
    attr_accessor :data

    def initialize parent, data
      super(parent)
      self.data = data
    end

    def to_s
      s = "{"
      s << data.map {|key, value| "#{key}: #{value}"}.join(', ')
      s << "}"
    end
  end

  def self.compile_stmts context, stmts, options = {}
    result = []
    if not stmts.empty?
      stmts[0..-2].each do |stmt|
        # TODO: check whether item includes "(return <anything>)" in any descendants
        result << context.process(stmt)
      end
      result << context.assign(context.ref('$result'), context.process(stmts[-1]))
    end
    result
  end
end
