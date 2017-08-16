class Gene::Types::ComplexString < Gene::Types::Base
  def initialize *items
    concat items
  end

  def == other
    return unless other.is_a? Gene::Types::ComplexString

    super
  end

  def to_s
    "(\"\" #{map(&:inspect).join(' ')})"
  end
end
