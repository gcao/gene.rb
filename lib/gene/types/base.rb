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
    s << type.to_s << ' '
    s << data.map do |child|
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
