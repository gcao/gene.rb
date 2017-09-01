class Gene::Lang::Deserializer
  def process input
    references, obj = Gene::Parser.parse input

    references = process_references references

    transform obj, references
  end

  private

  def process_references raw_references
    references = {}

    # Process top level
    raw_references.each do |key, value|
      if value.is_a? Array
        processed = value
      elsif value.is_a? Hash
        if value["#class"] == "Gene::Lang::Classs"
          processed = Gene::Lang::Class.new value["name"]
        elsif value["#class"] == "Gene::Lang::Scope"
          processed = Gene::Lang::Scope.new
        elsif value["#class"] == "Gene::Lang::Function"
          processed = Gene::Lang::Function.new value["name"]
        elsif value["#class"] == "Gene::Lang::Object"
          processed = Gene::Lang::Object.new
        else
          processed = value
        end

        if processed.is_a? Gene::Lang::Object
          value.each do |k, v|
            if k != "#class"
              processed.attributes[k] = v
            end
          end
        end
      end

      references[key] = processed
    end

    # Process deeper level
    references.each_value do |value|
      if value.is_a? Array
        value.each_with_index do |item, i|
          value[i] = transform item, references
        end
      elsif value.is_a? Hash
        value.attributes.each do |k, v|
          value[k] = transform v, references
        end
      elsif value.is_a? Gene::Lang::Object
        value.attributes.each do |k, v|
          value.attributes[k] = transform v, references
        end
      end
    end

    references
  end

  def transform obj, references
    case obj
    when Hash
      if obj["#class"] == "Gene::Lang::Class"
        result = Gene::Lang::Class.new obj["name"]
        result.instance_methods = transform obj["instance_methods"], references
        result.properties       = transform obj["properties"], references

      elsif obj["#class"] == "Gene::Lang::Scope"
        result = Gene::Lang::Scope.new transform obj["parent"], references
        result.variables = transform obj["variables"], references
        result.arguments = transform obj["arguments"], references

      elsif obj["#class"] == "Gene::Lang::Function"
        result = Gene::Lang::Function.new obj["name"]
        result.parent_scope = transform obj["parent_scope"], references
        result.arguments    = transform obj["arguments"], references
        result.statements   = transform obj["statements"], references

      elsif obj["#class"] == "Gene::Lang::Object"
        result = Gene::Lang::Object.new
        obj.each do |key, value|
          result[key] = transform value, references
        end

      elsif obj["#class"] == "Reference"
        id     = obj["id"]
        result = references[id]

      else
        result = obj
        result.each do |key, value|
          result[key] = transform value, references
        end
      end

    else
      result = obj
    end

    result
  end
end
