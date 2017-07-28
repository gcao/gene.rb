class Gene::Handlers::Lang::FunctionHandler
  FUNCTION = Gene::Types::Ident.new('fn')

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    if data.is_a? Gene::Types::Group and data.first == FUNCTION
      Gene::Lang::Function.new data[1].to_s
    else
      Gene::NOT_HANDLED
    end
  end
end
