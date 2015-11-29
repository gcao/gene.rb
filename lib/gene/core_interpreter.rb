module Gene
  class CoreInterpreter < AbstractInterpreter

    def self.parse_and_process input
      new.process(Parser.parse(input))
    end

    def initialize
      super
      @handlers.add Gene::Handlers::GroupHandler.new, 100
    end

  end
end

