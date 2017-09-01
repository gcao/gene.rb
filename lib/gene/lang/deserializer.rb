class Gene::Lang::Deserializer
  def process input
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

  def deserialize_gene obj, references
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
