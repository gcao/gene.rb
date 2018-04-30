class Gene::Types::Symbol
  attr :name
  attr :escaped

  def initialize name, escaped = false
    @name = name
    @escaped = escaped
  end

  def is_decorator?
    @name.length > 1 and @name[0] == '+' and @name != '+='
  end

  def == other
    return false unless other.is_a? self.class
    @name == other.name and @escaped == other.escaped
  end
  alias eql? ==

  def hash
    name.hash
  end

  def === other
    other.is_a? Gene::Types::Base and other.type == self
  end

  def to_s
    s = name.gsub(/([\(\)\[\]\{\}])/, '[' => '\\[', ']' => '\\]', '(' => '\\(', ')' => '\\)', '{' => '\\{', '}' => '\\}')
    @escaped ? "\\#{s}" : s
  end
  alias inspect to_s
end
