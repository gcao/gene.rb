class Gene::Lang::Interpreter
  attr_accessor :context

  def initialize context
    init_handlers
    @context = context
  end

  def init_handlers
    @handlers = Gene::Handlers::ComboHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefaultHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ModuleHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ClassHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ExtendHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IncludeHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PropHandler.new
    @handlers.add 100, Gene::Lang::Handlers::MethodHandler.new
    @handlers.add 100, Gene::Lang::Handlers::FunctionHandler.new
    @handlers.add 100, Gene::Lang::Handlers::SuperHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefHandler.new
    # @handlers.add 100, Gene::Lang::Handlers::LetHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AssignmentHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IfHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ForHandler.new
    @handlers.add 100, Gene::Lang::Handlers::LoopHandler.new
    @handlers.add 100, Gene::Lang::Handlers::NewHandler.new
    @handlers.add 100, Gene::Lang::Handlers::CallHandler.new
    @handlers.add 100, Gene::Lang::Handlers::CastHandler.new
    @handlers.add 100, Gene::Lang::Handlers::InitHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PrintHandler.new
    @handlers.add 100, Gene::Lang::Handlers::BinaryExprHandler.new
    @handlers.add 50,  Gene::Lang::Handlers::InvocationHandler.new
    @handlers.add 0,   Gene::Lang::Handlers::CatchAllHandler.new
  end

  def load_core_libs
    parse_and_process File.read(File.dirname(__FILE__) + '/core.glang')
  end

  def parse_and_process input
    parsed = Gene::Parser.parse input
    process parsed
  end

  def process data
    result = nil

    if data.is_a? Gene::Types::Stream
      data.each do |item|
        result = @handlers.call @context, item
      end
    else
      result = @handlers.call @context, data
    end

    result
  end
end
