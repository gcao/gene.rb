class Gene::Types::Array < ::Array
  def to_s
    '[' + each.map(&:inspect).join(' ') + ']'
  end
  alias inspect to_s
end