class Gene::Handlers::Lang::InvocationHandler
  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    # If first is an ident that starts with [a-zA-Z]
    #   treat as a variable (pointing to function or value)
    # If there are two or more elements in the group,
    #   treat as invocation
    # If the second element is !,
    #   treat as invocation with no argument
    return Gene::NOT_HANDLED unless
      data.is_a? Gene::Types::Group and
      data.first.is_a? Gene::Types::Ident and
      data.first.name =~ /^[a-zA-Z]/

    name  = data.first.name
    value = context.scope[name]
    if data.size == 1
      value
    elsif data.second == Gene::Types::Ident.new('!')
      value.call context: context
    else
      value.call context: context, arguments: data.rest
    end
  end
end
