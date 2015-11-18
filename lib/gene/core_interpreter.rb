module Gene
  class CoreInterpreter < AbstractInterpreter

    def self.parse_and_process input
      new.process(Parser.parse(input))
    end

    def initialize
      super
      @handlers = [
        Gene::Handlers::ArrayHandler.new,
        Gene::Handlers::HashHandler.new,
        Gene::Handlers::ComplexStringHandler.new,
        Gene::Handlers::RangeHandler.new,
        Gene::Handlers::Base64Handler.new,
        Gene::Handlers::MetadataHandler.new,
        Gene::Handlers::RegexpHandler.new,
        Gene::Handlers::ReferenceHandler.new,
        Gene::Handlers::GroupHandler.new,
      ]
    end

  end
end

