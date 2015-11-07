module Gene
  class TypesInterpreter < AbstractInterpreter

    def self.parse_and_process input
      new.process(Parser.new(input).parse)
    end

    def initialize
      super
      @handlers = [
        Gene::Handlers::ArrayHandler.new(self),
        Gene::Handlers::HashHandler.new(self),
        Gene::Handlers::RangeHandler.new(self),
        Gene::Handlers::Base64Handler.new(self),
      ]
    end

  end
end

