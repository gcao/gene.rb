class Gene::Types::Noop
  def == other
    other.is_a? self.class
  end

  def to_s
    '()'
  end
end

