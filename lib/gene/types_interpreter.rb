module Gene
  class TypesInterpreter < AbstractInterpreter

    def self.parse_and_process input
      new.process(Parser.new(input).parse)
    end

    def initialize
      super
      @handlers = [
        Gene::Handlers::ArrayHandler.new,
        Gene::Handlers::HashHandler.new,
        Gene::Handlers::RangeHandler.new,
        Gene::Handlers::Base64Handler.new,
        Gene::Handlers::GroupHandler.new,
      ]
    end

  end
end

