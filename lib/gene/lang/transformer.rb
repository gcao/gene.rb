class Gene::Lang::Transformer
  %W(
    IF ELSE_IF ELSE
    FN FNX FNXX
    CLASS EXTEND METHOD
    IMPORT FROM AS
    TRY CATCH
  ).each do |name|
    const_set name, Gene::Types::Symbol.new("#{name.downcase}")
  end

  def call input, options = {}
    if not input.is_a? Gene::Types::Base
      return input
    end

    if input === IF
      transform_if input, options
    elsif input === FN or input === FNX or input === FNXX
      transform_fn input, options
    elsif input === METHOD
      transform_method input, options
    elsif input === CLASS
      transform_class input, options
    elsif input === IMPORT
      transform_import input, options
    else
      input
    end
  end

  def transform_if input, options
    result = Gene::Types::Base.new(Gene::Types::Symbol.new('if$'))

    if_expr = result
    status  = :if
    input.data.each do |item|
      if status == :if
        status = :cond
        if_expr['cond'] = call(item)
        if_expr['then'] = Gene::Lang::Statements.new
      elsif status == :cond
        if item == ELSE_IF
          # TODO
          # status = :if
          # new_if_expr = Gene::Types::Base.new('if$')
          # if_expr['else'] = new_if_expr
        elsif item == ELSE
          status = :else
          if_expr['else'] = Gene::Lang::Statements.new
        else
          if_expr['then'] << call(item)
        end
      elsif status == :else
        if_expr['else'] << call(item)
      end
    end

    result
  end

  def transform_fn input, options
    result = Gene::Types::Base.new(Gene::Types::Symbol.new('fn$'))
    result['options'] = input.properties

    if input.type == FNX
      name = nil
      args = input.data[0]
      body = input.data[1..-1]
    elsif input.type == FNXX
      name = nil
      args = []
      body = input.data
    else
      name = input.data[0]
      args = input.data[1]
      body = input.data[2..-1]
    end

    result['name'] = name

    if args.is_a? Gene::Types::Symbol
      if args.to_s == "_"
        args = []
      else
        args = [args]
      end
    end

    result['args'] = Gene::Lang::Matcher.from_array args
    result['body'] = Gene::Lang::Statements.new(body || [])
    result
  end

  def transform_method input, options
    result = Gene::Types::Base.new(Gene::Types::Symbol.new('method$'))
    result['name'] = input.data[0]
    args = input.data[1]
    if args.is_a? Gene::Types::Symbol
      if args.to_s == "_"
        args = []
      else
        args = [args]
      end
    end
    result['args'] = Gene::Lang::Matcher.from_array args
    result['body'] = Gene::Lang::Statements.new input.data[2..-1] || []
    result
  end

  def transform_class input, options
    result = Gene::Types::Base.new(Gene::Types::Symbol.new('class$'))

    result['name'] = input.data[0]

    if input.data[1] == EXTEND
      result['super_class'] = input.data[2]
      result['body'] = Gene::Lang::Statements.new input.data[3..-1]
    else
      result['body'] = Gene::Lang::Statements.new input.data[1..-1]
    end

    result
  end

  def transform_import input, options
    result = Gene::Types::Base.new(Gene::Types::Symbol.new('import$'))

    mappings = {}
    source   = nil

    state = :mapping_name
    name  = nil
    input.data.each do |item|
      if state == :mapping_name
        if item == AS
          raise "Name of the source member is required"
        elsif item == FROM
          state = :from
        else
          state = :mapping_as
          name  =  item
        end
      elsif state == :mapping_as
        if item == AS
          state = :mapping_value
        elsif item == FROM
          state = :from
          mappings[name.to_s] = handle_mapping_value(name)
        else
          state = :mapping_as
          name  = item
        end
      elsif state == :mapping_value
        state = :mapping_name
        mappings[name.to_s] = handle_mapping_value(item)
      elsif state == :from
        state  = :done
        source = item
      elsif state == :done
        raise "Syntax error: no more content is allowed"
      end
    end

    if state != :done
      raise "Syntax error: import statement is incomplete"
    end

    result['mappings'] = mappings
    result['source']   = source
    result
  end

  def handle_mapping_value value
    value = value.to_s
    if value.index "/"
      value = value[(value.rindex("/") + 1)..-1]
    end
    value
  end
end
