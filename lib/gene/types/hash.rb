class Gene::Types::Hash < ::Hash
  def to_s
    s = "{"
    s << map {|key, value|
      "^#{key} #{value.inspect}"
    }.join(" ")
    s << "}"
  end
  alias inspect to_s
end