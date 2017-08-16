class Gene::Types::Ident
  attr :name
  attr :escaped

  def initialize name, escaped = false
    @name = name
    @escaped = escaped
  end

  def == other
    return false unless other.is_a? self.class
    @name == other.name and @escaped == other.escaped
  end
  alias_method :eql?, :==

  def to_s
    s = name.gsub(/([\(\)\[\]\{\}])/, '[' => '\\[', ']' => '\\]', '(' => '\\(', ')' => '\\)', '{' => '\\{', '}' => '\\}')
    @escaped ? "\\#{s}" : s
  end

  def inspect
    to_s
  end

  def first_of_group? arg
    arg.is_a? Gene::Types::Base and arg.first == self
  end
end
