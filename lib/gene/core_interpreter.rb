module Gene
  class CoreInterpreter < AbstractInterpreter

    def self.parse_and_process input
      new.process(Parser.parse(input))
    end

    def initialize
      super
      @handlers.push(
        Gene::Handlers::GroupHandler.new,
      )
    end

  end
end

