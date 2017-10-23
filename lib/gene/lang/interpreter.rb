class Gene::Lang::Interpreter
  attr_accessor :context

  def initialize context
    init_handlers
    @context = context
  end

  def init_handlers
    @handlers = Gene::Handlers::ComboHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefaultHandler.new
    @handlers.add 100, Gene::Lang::Handlers::NamespaceHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ImportHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AccessLevelHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PropHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ModuleHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ClassHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ExtendHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IncludeHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PropHandler.new
    @handlers.add 100, Gene::Lang::Handlers::MethodHandler.new
    @handlers.add 100, Gene::Lang::Handlers::FunctionHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AspectHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AdviceHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ContinueHandler.new
    @handlers.add 100, Gene::Lang::Handlers::SuperHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AssignmentHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IfHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ForHandler.new
    @handlers.add 100, Gene::Lang::Handlers::LoopHandler.new
    @handlers.add 100, Gene::Lang::Handlers::NewHandler.new
    @handlers.add 100, Gene::Lang::Handlers::CallHandler.new
    @handlers.add 100, Gene::Lang::Handlers::CastHandler.new
    @handlers.add 100, Gene::Lang::Handlers::InitHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PrintHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AssertHandler.new
    @handlers.add 100, Gene::Lang::Handlers::BinaryExprHandler.new
    @handlers.add 50,  Gene::Lang::Handlers::InvocationHandler.new
    @handlers.add 0,   Gene::Lang::Handlers::CatchAllHandler.new
  end

  def load_core_libs
    parse_and_process File.read(File.dirname(__FILE__) + '/core.gene')
  end

  def parse_and_process input
    parsed = Gene::Parser.parse input
    process parsed
  end

  def process data
    result = nil

    data = process_decorators data

    if data.is_a? Gene::Types::Stream
      data.each do |item|
        result = @handlers.call @context, item
      end
    else
      result = @handlers.call @context, data
    end

    result
  end

  private

  def process_decorators data
    if data.is_a? Gene::Types::Stream
      process_decorators_in_array data
    elsif data.is_a? Array
      process_decorators_in_array data
    elsif data.is_a? Gene::Types::Base
      data.data = process_decorators_in_array data.data
      data
    else
      data
    end
  end

  def process_decorators_in_array data
    decorators = []
    i = 0
    while i < data.length
      item = data[i]
      if is_decorator? item
        decorators.push item
        data.delete_at i
      elsif decorators.empty?
        i += 1
      else
        data[i] = apply_decorators decorators, item
        i += 1
      end
    end

    data
  end

  def is_decorator? item
    (item.is_a? Gene::Types::Symbol and item.is_decorator?) or
    (item.is_a? Gene::Types::Base and item.type.is_a? Gene::Types::Symbol and item.type.is_decorator?)
  end

  def apply_decorators decorators, item
    while not decorators.empty?
      decorator = decorators.pop

      if decorator.is_a? Gene::Types::Symbol
        decorator = Gene::Types::Base.new decorator, item
      else
        decorator.data.push item
      end

      decorator.type = Gene::Types::Symbol.new decorator.type.to_s[1..-1]

      item = decorator
    end

    item
  end
end
