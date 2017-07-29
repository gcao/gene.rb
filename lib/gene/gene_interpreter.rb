module Gene
  #
  # Gene will be our own interpreted language
  #
  class GeneInterpreter

    def initialize
      @handlers = Gene::Handlers::ComboHandler.new
      @handlers.add 100, Gene::Handlers::Lang::ClassHandler.new
      @handlers.add 100, Gene::Handlers::Lang::FunctionHandler.new
      @handlers.add 100, Gene::Handlers::Lang::LetHandler.new
    end

    def parse_and_process input
      CoreInterpreter.parse_and_process input do |output|
        process output
      end
    end

    def process data
      @handlers.call self, data
    end
  end
end

