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
    @handlers.add 100, Gene::Lang::Handlers::LetHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IfHandler.new
    @handlers.add 100, Gene::Lang::Handlers::NewHandler.new
    @handlers.add 100, Gene::Lang::Handlers::InitHandler.new
    @handlers.add 100, Gene::Lang::Handlers::BinaryExprHandler.new
    @handlers.add 100, Gene::Lang::Handlers::InvocationHandler.new

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

  def parse_and_process input
    Gene::CoreInterpreter.parse_and_process input do |output|
      process output
    end
  end

  def process data
    @handlers.call self, data
  end
end
