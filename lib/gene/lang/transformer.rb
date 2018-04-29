class Gene::Lang::Transformer
  %W(
    IF ELSE_IF ELSE
    FN
  ).each do |name|
    const_set name, Gene::Types::Symbol.new("#{name.downcase}")
  end

  def call input, options = {}
    if not input.is_a? Gene::Types::Base
      return input
    end

    if input === IF
      transform_if input, options
    elsif input === FN
      transform_fn input, options
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
    result['body'] = Gene::Lang::Statements.new input.data[2..-1]
    result
  end
end
