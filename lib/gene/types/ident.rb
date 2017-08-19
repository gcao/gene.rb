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
  alias eql? ==

  def === other
    other.is_a? Gene::Types::Base and other.type == self
  end

  def to_s
    s = name.gsub(/([\(\)\[\]\{\}])/, '[' => '\\[', ']' => '\\]', '(' => '\\(', ')' => '\\)', '{' => '\\{', '}' => '\\}')
    @escaped ? "\\#{s}" : s
  end
  alias inspect to_s
end
