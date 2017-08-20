class Gene::Types::Base
  attr_accessor :type, :data
  attr_reader :attributes

  def initialize type, *data
    @type = type
    @data = [].concat data
    @attributes = {}
  end

  def [] name
    @attributes[name.to_s]
  end

  def []= name, value
    @attributes[name.to_s] = value
  end

  def == other
    return unless other.is_a? self.class

    type == other.type and data == other.data and attributes == other.attributes
  end

  def === other
    @type == other
  end

  def to_s
    s = "("
    s << type.to_s
    data.each do |child|
      s << ' ' << child.inspect
    end
    s << ")"
  end
  alias inspect to_s
end
