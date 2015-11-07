class Gene::Types::Base64
  attr :data

  def initialize data
    @data = data
  end

  def == other
    return false unless other.is_a? self.class
    @data == other.data
  end

  def to_s
    "(base64 \"#{@data}\")"
  end
end

