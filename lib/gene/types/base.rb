class Gene::Types::Base
  attr_accessor :type, :data
  attr_accessor :properties

  def initialize type, *data
    @type = type
    @data = [].concat data
    @properties = {}
  end

  def [] name
    @properties[name.to_s]
  end

  def []= name, value
    @properties[name.to_s] = value
  end

  def == other
    return unless other.is_a? self.class

    type == other.type and data == other.data and properties == other.properties
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
