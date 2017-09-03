require 'gene/lang/types'
require 'gene/lang/handlers'

#
# Gene will be our own interpreted language
#
class Gene::Lang::Interpreter
  attr_reader   :global_scope

  def initialize
    @handlers = Gene::Handlers::ComboHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefaultHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ClassHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ExtendHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PropertyHandler.new
    @handlers.add 100, Gene::Lang::Handlers::MethodHandler.new
    @handlers.add 100, Gene::Lang::Handlers::FunctionHandler.new
    @handlers.add 100, Gene::Lang::Handlers::SuperHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefHandler.new
    @handlers.add 100, Gene::Lang::Handlers::LetHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IfHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ForHandler.new
    @handlers.add 100, Gene::Lang::Handlers::LoopHandler.new
    @handlers.add 100, Gene::Lang::Handlers::NewHandler.new
    @handlers.add 100, Gene::Lang::Handlers::CallHandler.new
    @handlers.add 100, Gene::Lang::Handlers::CastHandler.new
    @handlers.add 100, Gene::Lang::Handlers::InitHandler.new
    @handlers.add 100, Gene::Lang::Handlers::BinaryExprHandler.new
    @handlers.add 50, Gene::Lang::Handlers::InvocationHandler.new

    reset
  end

  def reset
    # global_scope is a special scope
    # root_scope is the root of regular scope hierarchy: @scopes
    # regular scopes can inherit or not inherit from a higher level scope
    @global_scope = Gene::Lang::Scope.new nil
    @root_scope   = Gene::Lang::Scope.new nil
    @scopes       = [@root_scope]
    @self_objects = []

    parse_and_process %q`
      # Wrapper class for native arrays
      (class Array
        (method class []
          ($invoke $context "get" "Array")
        )
        (method size []
          ($invoke self "size")
        )
        (method get [i]
          ($invoke self [] i)
        )
        (method each [f]
          (for (let i 0) (i < (.size)) (let i (i + 1))
            (let item (.get i))
            (f item i)
          )
        )
      )
    `
  end

  def scope
    @scopes.last
  end

  def start_scope scope = Gene::Lang::Scope.new(nil)
    @scopes.push scope
  end

  def end_scope
    throw "Scope error: can not close the root scope." if @scopes.size == 0
    @scopes.pop
  end

  def self
    @self_objects.last
  end

  def start_self self_object
    @self_objects.push self_object
  end

  def end_self
    @self_objects.pop
  end

  def get name
    if scope.defined? name
      scope.get_variable name
    else
      @global_scope.get_variable name
    end
  end
  alias [] get

  def parse_and_process input
    Gene::CoreInterpreter.parse_and_process input do |output|
      process output
    end
  end

  def process data
    @handlers.call self, data
  end

  def process_statements statements
    result = Gene::UNDEFINED
    return result if statements.nil?

    [statements].flatten.each do |stmt|
      result = process stmt
      if result.is_a?(Gene::Lang::ReturnValue) or result.is_a?(Gene::Lang::BreakValue)
        break
      end
    end

    result
  end

  def serialize
    {
      "global_scope"  => @global_scope.inspect,
      "scopes"        => @scopes.inspect,
      "self_objects"  => @self_objects.inspect
    }.to_json
  end

  def deserialize input
    parsed        = JSON.parse input
    @global_scope = parsed["global_scope"]
    @scopes       = parsed["scopes"]
    @self_objects = parsed["self_objects"]
  end
end
