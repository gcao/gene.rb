class Gene::Handlers::Lang::ClassHandler
  CLASS = Gene::Types::Ident.new('class')

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    if data.is_a? Gene::Types::Group and data.first == CLASS
      stmts = data[2..-1].map do |stmt|
        context.process stmt
      end
      block = Gene::Lang::Block.new stmts
      klass = Gene::Lang::Class.new data[1].to_s, block
    else
      Gene::NOT_HANDLED
    end
  end
end
