class Gene::Lang::Serializer
  def process obj
    result = "{"

    references = get_references obj
    result << '"references": ' << serialize_references(references) << ", "

    result << '"data": ' << serialize_with_references(obj, references)

    result + "}"
  end

  private

  def get_references obj
    references = {}
    calc_references obj, references

    result = {}
    references.each do |key, pair|
      if pair[1] > 1
        result[key] = pair[0]
      end
    end
    result
  end

  def calc_references obj, references
    id_str = obj.object_id.to_s

    case obj
    when Array
      if references.include? id_str
        references[id_str][1] += 1
      else
        # Seen for the first time
        references[id_str] = [obj, 1]

        # Traverse its children
        obj.each do |item|
          calc_references item, references
        end
      end

    when Hash
      if references.include? id_str
        references[id_str][1] += 1
      else
        # Seen for the first time
        references[id_str] = [obj, 1]

        # Traverse its children
        obj.each do |key, value|
          calc_references value, references
        end
      end

    when Gene::Lang::Object
      if references.include? id_str
        references[id_str][1] += 1
      else
        # Seen for the first time
       references[id_str] = [obj, 1]

        # Traverse its children
        obj.properties.each do |key, value|
          calc_references value, references
        end
      end
    end

    references
  end

  def serialize_references references
    result = "{"

    result << references.map do |key, value|
      serialized_value = serialize value, references
      "\"#{key}\": #{serialized_value}"
    end.join(", ")

    result + "}"
  end

  def serialize_with_references obj, references
    id_str = obj.object_id.to_s
    if references.include? id_str
      return '{"#class": "Reference", "id": "' + id_str + '"}'
    end

    serialize obj, references
  end

  def serialize obj, references
    result = ""

    case obj
    when Array
      result << "["
      result << obj.map {|item| "#{serialize_with_references(item, references)}" }.join(", ")
      result << "]"
    when Hash
      result << "{"
      result << obj.to_a.map {|pair| "#{pair[0].inspect}: #{serialize_with_references(pair[1], references)}" }.join(", ")
      result << "}"
    when Gene::Lang::Object
      result << "{"
      class_and_properties = obj.properties.to_a.unshift(["#class", obj.class])
      result << class_and_properties.map {|pair| "#{pair[0].inspect}: #{serialize_with_references(pair[1], references)}" }.join(", ")
      result << "}"
    when ::Class
      result << obj.name.inspect
    when NilClass
      result << "null"
    else
      result << obj.inspect
    end

    result
  end
end
