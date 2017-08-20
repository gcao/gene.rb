class Gene::Types::Tuple
  attr :data

  def initialize *data
    @data = data
  end

  def == other
    return false unless other.is_a? self.class
    @data == other.data
  end

  def to_s
    "(#|| #{data.map(&:inspect).join(' ')})"
  end
  alias inspect to_s
end
