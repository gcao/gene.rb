class Gene::Handlers::Lang::BinaryExprHandler
  BINARY_OPERATORS = [
    Gene::Types::Ident.new('+'),
    Gene::Types::Ident.new('-'),
    Gene::Types::Ident.new('*'),
    Gene::Types::Ident.new('/'),
  ]

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group and BINARY_OPERATORS.include?(data.second)

    op    = data.second.name
    left  = context.process(data.first)
    right = context.process(data.third)
    case op
    when '+' then left + right
    when '-' then left - right
    when '*' then left * right
    when '/' then left / right
    end
  end
end
