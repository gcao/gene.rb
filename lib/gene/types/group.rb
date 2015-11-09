class Gene::Types::Group < Array
  attr_accessor :root, :parent
  attr :metadata

  def initialize *items
    @metadata = {}
    concat items
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
end
