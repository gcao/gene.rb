class Gene::Lang::Interpreter
  attr_accessor :context

  def initialize context
    init_handlers
    @context = context
  end

  def init_handlers
    @handlers = Gene::Handlers::ComboHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefaultHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ExpandHandler.new
    @handlers.add 100, Gene::Lang::Handlers::NamespaceHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ImportHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AccessLevelHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PropHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ModuleHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ClassHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IncludeHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PropHandler.new
    @handlers.add 100, Gene::Lang::Handlers::MethodHandler.new
    @handlers.add 100, Gene::Lang::Handlers::FunctionHandler.new
    @handlers.add 100, Gene::Lang::Handlers::MatchHandler.new
    @handlers.add 100, Gene::Lang::Handlers::BindHandler.new
    @handlers.add 100, Gene::Lang::Handlers::MacroHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AspectHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AdviceHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ContinueHandler.new
    @handlers.add 100, Gene::Lang::Handlers::SuperHandler.new
    @handlers.add 100, Gene::Lang::Handlers::DefinitionHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AssignmentHandler.new
    @handlers.add 100, Gene::Lang::Handlers::IfHandler.new
    # @handlers.add 100, Gene::Lang::Handlers::ForHandler.new
    @handlers.add 100, Gene::Lang::Handlers::LoopHandler.new
    @handlers.add 100, Gene::Lang::Handlers::NewHandler.new
    @handlers.add 100, Gene::Lang::Handlers::CallHandler.new
    @handlers.add 100, Gene::Lang::Handlers::CastHandler.new
    @handlers.add 100, Gene::Lang::Handlers::InitHandler.new
    @handlers.add 100, Gene::Lang::Handlers::WithHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ScopeHandler.new
    @handlers.add 100, Gene::Lang::Handlers::ExceptionHandler.new
    @handlers.add 100, Gene::Lang::Handlers::PrintHandler.new
    @handlers.add 100, Gene::Lang::Handlers::AssertHandler.new
    @handlers.add 100, Gene::Lang::Handlers::BinaryExprHandler.new
    @handlers.add 50,  Gene::Lang::Handlers::RenderHandler.new
    @handlers.add 50,  Gene::Lang::Handlers::InvocationHandler.new
    @handlers.add 0,   Gene::Lang::Handlers::CatchAllHandler.new
  end

  def load_core_libs
    parse_and_process File.read(File.dirname(__FILE__) + '/core.gene')
  end

  def parse_and_process input
    parsed = Gene::Parser.parse input
    result = process parsed
    # convert Gene exception to ruby exception
    if result.is_a? Gene::Lang::ThrownException
      raise result.exception.get('message')
    end
    result
  end

  def process data
    result = nil

    data = process_decorators data

    if data.is_a? Gene::Types::Stream
      data.each do |item|
        result = @handlers.call @context, item

        # TODO: should we allow break / return on the top level?
        if (result.is_a?(Gene::Lang::ReturnValue) or
            result.is_a?(Gene::Lang::BreakValue) or
            result.is_a?(Gene::Lang::ThrownException))
          break
        end
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
        decorators = []
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

      item =
        if decorator.is_a? Gene::Types::Symbol
          Gene::Types::Base.new Gene::Types::Symbol.new(decorator.to_s[1..-1]), item
        else
          decorator.type = Gene::Types::Symbol.new(decorator.type.to_s[1..-1])
          Gene::Types::Base.new decorator, item
        end
    end

    item
  end
end
