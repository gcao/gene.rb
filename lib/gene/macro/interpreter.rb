class Gene::Macro::Interpreter
  def initialize
    @handlers = Gene::Handlers::ComboHandler.new
    @handlers.add 100, Gene::Macro::Handlers::DefaultHandler.new
    reset
  end

  def reset
    @root_scope = Gene::Macro::Scope.new nil
    @scopes     = [@root_scope]
  end

  def scope
    @scopes.last
  end

  def start_scope new_scope = nil
    new_scope ||= Gene::Macro::Scope.new(scope)
    @scopes.push new_scope
    new_scope
  end

  def end_scope scope
    throw "Scope error: can not close the root scope." if @scopes.size == 0
    if !scope or self.scope == scope
      @scopes.pop
    end
  end

  attr :inputs
  # def inputs= *args
  #   @inputs = args
  # end

  def parse_and_process input, *args
    @inputs = args
    process Gene::Parser.parse(input)
  ensure
    @inputs = nil
  end

  def process data
    result = process_internal data
    if result == Gene::Macro::IGNORE
      Gene::UNDEFINED
    elsif result.is_a? Gene::Macro::YieldValue
      result.value
    elsif result.is_a? Gene::Macro::YieldValues
      result.values
    else
      result
    end
  end

  def process_internal data
    result = nil

    if data.is_a? Gene::Types::Stream
      data.each do |item|
        result = @handlers.call self, item
      end
    else
      result = @handlers.call self, data
    end

    result
  end
end
