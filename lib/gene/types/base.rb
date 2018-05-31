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

    @properties.each do |name, value|
      next if name.to_s =~ /^\$/
      next if %W(#type #class #data).include? name.to_s

      s << " "

      if value == true
        s << "^^#{name}"
      elsif value == false
        s << "^!#{name}"
      elsif value.is_a? Gene::Types::Base
        s << "^#{name}" << value.to_s_short
      elsif value.class.name == "Array"
        s << "^#{name} "
        if value.empty?
          s << "[]"
        else
          s << "[...]"
        end
      elsif value.class.name == "Hash"
        s << "^#{name} "
        if value.empty?
          s << "{}"
        else
          s << "{...}"
        end
      else
        s << "^#{name} " << value.inspect
      end
    end

    data.each do |child|
      s << ' '

      if child.is_a? Gene::Types::Base
        s << child.to_s_short
      elsif child.class.name == "Array"
        if child.empty?
          s << "[]"
        else
          s << "[...]"
        end
      elsif child.class.name == "Hash"
        if child.empty?
          s << "{}"
        else
          s << "{...}"
        end
      else
        s << child.inspect
      end
    end
    s << ")"
  end
  alias inspect to_s

  def to_s_short
    s = "("
    s << type.to_s

    if not @data.empty? or not @properties.empty?
      s << " ..."
    end

    s << ")"
  end
end
