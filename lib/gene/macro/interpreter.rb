require 'gene/macro/types'
require 'gene/macro/handlers'

class Gene::Macro::Interpreter
  def initialize
    @handlers = Gene::Handlers::ComboHandler.new
    @handlers.add 100, Gene::Macro::Handlers::DefaultHandler.new
    reset
  end

  def reset
    @root_scope = Gene::Macro::Scope.new nil
    @scopes     = [@root_scope]
  end

  def scope
    @scopes.last
  end

  def start_scope
    new_scope = Gene::Macro::Scope.new(scope)
    @scopes.push new_scope
    new_scope
  end

  def end_scope scope
    throw "Scope error: can not close the root scope." if @scopes.size == 0
    if !scope or self.scope == scope
      @scopes.pop
    end
  end

  def parse_and_process input
    process Gene::Parser.parse(input)
  end

  def process data
    result = nil

    if data.is_a? Gene::Types::Stream
      data.each do |item|
        result = @handlers.call self, item
      end
    else
      result = @handlers.call self, data
    end

    if result == Gene::Macro::IGNORE
      Gene::UNDEFINED
    else
      result
    end
  end
end
