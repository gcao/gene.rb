class Gene::Types::Base
  attr_accessor :type, :data
  attr_accessor :properties

  def initialize type, *data
    @type = type
    @data = [].concat data
    @properties = {}
  end

  def get name
    if name.is_a? String
      @properties[name.to_s]
    else
      @data[name]
    end
  end
  alias [] get

  def set name, value
    if name.is_a? Fixnum
      @data[name] = value
    else
      @properties[name.to_s] = value
    end
  end
  alias []= set

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
