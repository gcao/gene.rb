class Gene::Handlers::Lang::FunctionHandler
  FUNCTION = Gene::Types::Ident.new('fn')

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    return Gene::NOT_HANDLED unless FUNCTION.first_of_group? data
    name = data.second.to_s
    fn = Gene::Lang::Function.new name
    arguments = [data.third].flatten
      .select {|item| not item.nil? }
      .map {|item| Gene::Lang::Argument.new(item.name) }
    fn.block = Gene::Lang::Block.new arguments, data[3..-1]
    context.scope[name] = fn
    fn
  end
end
