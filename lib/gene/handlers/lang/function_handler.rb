class Gene::Handlers::Lang::FunctionHandler
  FUNCTION = Gene::Types::Ident.new('fn')

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    if data.is_a? Gene::Types::Group and data.first == FUNCTION
      name = data[1].to_s
      args = [data[2]].flatten
        .select {|item| not item.nil? }
        .map {|item| Gene::Lang::Argument.new(item.name) }
      Gene::Lang::Function.new name, args
    else
      Gene::NOT_HANDLED
    end
  end
end
