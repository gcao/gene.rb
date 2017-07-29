module Gene::Handlers::Lang
  class LetHandler
    LET = Gene::Types::Ident.new('let')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call context, data
      if data.is_a? Gene::Types::Group and data.first == LET
        value = data[2]
        Gene::Lang::Variable.new data[1].to_s, value
      else
        Gene::NOT_HANDLED
      end
    end
  end
end

require 'gene/handlers/lang/class_handler'
require 'gene/handlers/lang/function_handler'
