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
    if data.is_a? Gene::Types::Group and BINARY_OPERATORS.include?(data[1])
      case data[1].name
      when '+' then data[0] + data[2]
      when '-' then data[0] - data[2]
      when '*' then data[0] * data[2]
      when '/' then data[0] / data[2]
      end
    else
      Gene::NOT_HANDLED
    end
  end
end
