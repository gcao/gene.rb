require 'gene/macro/types'
require 'gene/macro/handlers'

module Gene::Macro
  #
  # Gene will be our own interpreted language
  #
  class Interpreter
    def initialize
      @handlers = Gene::Handlers::ComboHandler.new
      reset
    end

    def reset
      # TODO
      # @root_scope   = Gene::Lang::Scope.new nil
      # @scopes       = [@root_scope]
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

    def parse_and_process input
      Gene::CoreInterpreter.parse_and_process input do |output|
        process output
      end
    end

    def process data
      @handlers.call self, data
    end
  end
end
