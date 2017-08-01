class Gene::Handlers::Lang::ClassHandler
  CLASS = Gene::Types::Ident.new('class')

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    return Gene::NOT_HANDLED unless CLASS.first_of_group? data
    name  = data.second.to_s
    stmts = data[2..-1].map do |stmt|
      context.process stmt
    end
    block = Gene::Lang::Block.new nil, stmts
    klass = Gene::Lang::Class.new name, block
    block.call context: context
    context.scope[name] = klass
    klass
  end
end
