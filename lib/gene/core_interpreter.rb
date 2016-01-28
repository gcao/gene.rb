module Gene
  class CoreInterpreter < AbstractInterpreter

    def self.parse_and_process input, &block
      new.process(Parser.parse(input), &block)
    end

    def initialize
      super
      @handlers.add 100, Gene::Handlers::ArrayHandler.new
      @handlers.add 100, Gene::Handlers::HashHandler.new
      @handlers.add 100, Gene::Handlers::ComplexStringHandler.new
      @handlers.add 100, Gene::Handlers::RangeHandler.new
      @handlers.add 100, Gene::Handlers::Base64Handler.new
      @handlers.add 100, Gene::Handlers::RegexpHandler.new
      @handlers.add 100, Gene::Handlers::RefHandler.new
      @handlers.add 100, Gene::Handlers::SetHandler.new
      @handlers.add 50, Gene::Handlers::GroupHandler.new
    end

  end
end

