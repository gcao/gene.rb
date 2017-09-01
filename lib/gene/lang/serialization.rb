require "json"

module Gene::Lang
  def self.serialize obj
    result = ""

    references = get_references obj
    result = serialize_with_references obj, references

    if not references.empty?
      if result[0] == '['
        result.insert 1, serialize_references(references) + ", "
      elsif result [0] == '{'
        result.insert 1, "\"#references\": #{serialize_references(references)}, "
      end
    end

    result
  end

  def self.serialize_references references
    result = "{"

    result << '"#class": "References", '

    result << references.map do |key, value|
      serialized_value = serialize_ value, references
      "\"#{key}\": #{serialized_value}"
    end.join(", ")

    result + "}"
  end

  def self.serialize_with_references obj, references
    id_str = obj.object_id.to_s
    if references.include? id_str
      return '{"#class": "Reference", "id": "' + id_str + '"}'
    end

    serialize_ obj, references
  end

  def self.serialize_ obj, references
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
      result << obj.attributes.to_a.map {|pair| "#{pair[0].inspect}: #{serialize_with_references(pair[1], references)}" }.join(", ")
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

  def self.get_references obj
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

  def self.calc_references obj, references
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
        obj.attributes.each do |key, value|
          calc_references value, references
        end
      end
    end

    references
  end

  def self.deserialize input
    obj = Gene::Parser.parse input

    references = {}
    if obj.is_a? Array
      if obj[0].is_a? Hash and obj[0]["#class"] == "References"
        obj[0].delete "#class"
        references = obj[0]
      end
    elsif obj.is_a? Hash
      if obj.include? "#references"
        references = obj.delete '#references'
      end
    end

    # Clean up references hash
    references.delete "#class"

    parsed_references = {}
    references.each do |key, value|
      if value.is_a? Array
        parsed = value
      elsif value.is_a? Hash
        if value.is_a? Hash and value["#class"] == "Gene::Lang::Classs"
          parsed = Gene::Lang::Class.new obj["name"]
        elsif value.is_a? Hash and value["#class"] == "Gene::Lang::Scope"
          parsed = Gene::Lang::Scope.new
        elsif value.is_a? Hash and value["#class"] == "Gene::Lang::Function"
          parsed = Gene::Lang::Function.new obj["name"]
        elsif value.is_a? Hash and value["#class"] == "Gene::Lang::Object"
          parsed = Gene::Lang::Object.new
        else
          parsed = value
        end

        if parsed.is_a? Gene::Lang::Object
          value.each do |k, v|
            if k != "#class"
              parsed.attributes[k] = v
            end
          end
        end
      end

      parsed_references[key] = parsed
    end

    parsed_references.each_value do |value|
      if value.is_a? Array
        value.each_with_index do |item, i|
          value[i] = deserialize_gene item, parsed_references
        end
      elsif value.is_a? Hash
        value.attributes.each do |k, v|
          value[k] = deserialize_gene v, parsed_references
        end
      elsif value.is_a? Gene::Lang::Object
        value.attributes.each do |k, v|
          value.attributes[k] = deserialize_gene v, parsed_references
        end
      end
    end

    deserialize_gene obj, parsed_references
  end

  def self.deserialize_gene obj, references
    case obj
    when Hash
      if obj["#class"] == "Gene::Lang::Class"
        result = Gene::Lang::Class.new obj["name"]
        result.instance_methods = deserialize_gene obj["instance_methods"], references
        result.properties       = deserialize_gene obj["properties"], references

      elsif obj["#class"] == "Gene::Lang::Scope"
        result = Gene::Lang::Scope.new deserialize_gene obj["parent"], references
        result.variables = deserialize_gene obj["variables"], references
        result.arguments = deserialize_gene obj["arguments"], references

      elsif obj["#class"] == "Gene::Lang::Function"
        result = Gene::Lang::Function.new obj["name"]
        result.parent_scope = deserialize_gene obj["parent_scope"], references
        result.arguments    = deserialize_gene obj["arguments"], references
        result.statements   = deserialize_gene obj["statements"], references

      elsif obj["#class"] == "Gene::Lang::Object"
        result = Gene::Lang::Object.new
        obj.each do |key, value|
          result[key] = deserialize_gene value, references
        end

      elsif obj["#class"] == "Reference"
        id     = obj["id"]
        result = references[id]

      else
        result = obj
        result.each do |key, value|
          result[key] = deserialize_gene value, references
        end
      end

    else
      result = obj
    end

    result
  end
end
