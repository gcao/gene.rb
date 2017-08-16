class Gene::Types::Base
  attr_accessor :type
  attr_reader :attributes, :data

  def initialize type, *data
    @type = type
    @data = [].concat data
    @attributes = {}
  end

  def == other
    return unless other.is_a? self.class

    super
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
