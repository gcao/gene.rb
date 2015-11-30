module Gene
  class CoreInterpreter < AbstractInterpreter

    def self.parse_and_process input, &block
      new.process(Parser.parse(input), &block)
    end

    def initialize
      super
      @handlers.add Gene::Handlers::ArrayHandler.new, 100
      @handlers.add Gene::Handlers::HashHandler.new, 100
      @handlers.add Gene::Handlers::ComplexStringHandler.new, 100
      @handlers.add Gene::Handlers::RangeHandler.new, 100
      @handlers.add Gene::Handlers::Base64Handler.new, 100
      @handlers.add Gene::Handlers::RegexpHandler.new, 100
      @handlers.add Gene::Handlers::RefHandler.new, 100
      @handlers.add Gene::Handlers::GroupHandler.new, 100
    end

  end
end

