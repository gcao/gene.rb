class Gene::Types::Group < Array
  attr :attributes

  def initialize *items
    @attributes = {}
    concat items
  end

  def second
    self[1]
  end

  def third
    self[2]
  end

  def rest
    self[1..-1]
  end

  def == other
    return unless other.is_a? Gene::Types::Group

    super
  end

  def to_s
    s = "("
    s << map do |child|
      if child.is_a? String
        child.inspect
      else
        child.to_s
      end
    end.join(' ')
    s << ")"
  end

  def inspect
    to_s
  end
end
