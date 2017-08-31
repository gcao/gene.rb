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
    @handlers.add 100, Gene::Lang::Handlers::PropertyHandler.new
    @handlers.add 100, Gene::Lang::Handlers::MethodHandler.new
    @handlers.add 100, Gene::Lang::Handlers::FunctionHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefHandler.new
    @handlers.add 100, Gene::Lang::Handlers::LetHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IfHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ForHandler.new
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
      (class Array
        (method class []
          (_invoke _context "get" "Array")
        )
        (method size []
          (_invoke _self "size")
        )
        (method get [i]
          (_invoke _self [] i)
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
    end

    result
  end
end
