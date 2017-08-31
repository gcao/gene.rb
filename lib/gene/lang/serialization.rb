require "json"

module Gene::Lang
  def self.serialize obj
    result = ""
    case obj
    when Array
      result << "["
      result << obj.map {|item| "#{serialize(item)}" }.join(", ")
      result << "]"
    when Hash
      result << "{"
      result << obj.to_a.map {|pair| "#{pair[0].inspect}: #{serialize(pair[1])}" }.join(", ")
      result << "}"
    when Gene::Lang::Object
      result << "{"
      result << obj.attributes.to_a.map {|pair| "#{pair[0].inspect}: #{serialize(pair[1])}" }.join(", ")
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

  def self.deserialize input
    obj = JSON.parse input
    deserialize_json obj
  end

  def self.deserialize_json obj
    case obj
    when Hash
      if obj["#class"] == "Gene::Lang::Class"
        result = Gene::Lang::Class.new obj["name"]
        result.instance_methods = deserialize_json obj["instance_methods"]
        result.properties       = deserialize_json obj["properties"]

      elsif obj["#class"] == "Gene::Lang::Scope"
        result = Gene::Lang::Scope.new deserialize_json obj["parent"]
        result.variables = deserialize_json obj["variables"]
        result.arguments = deserialize_json obj["arguments"]

      elsif obj["#class"] == "Gene::Lang::Object"
        result = Gene::Lang::Object.new
        obj.each do |key, value|
          result[key] = value
        end

      else
        result = obj
      end
    end

    result
  end
end
