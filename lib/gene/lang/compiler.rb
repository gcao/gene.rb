class Gene::Lang::Compiler
  def initialize
    init_handlers
  end

  def init_handlers
    @handlers = Gene::Handlers::ComboHandler.new
    @handlers.add 100, DefaultHandler.new
  end

  def parse_and_process input
    parsed = Gene::Parser.parse input
    result = process parsed
    <<-JAVASCRIPT
      var $root_context = $application.create_root_context();
      (function($context){
        #{result}
      })($root_context);
    JAVASCRIPT
  end

  def process data
    result = @handlers.call self, data
  end

  PLACEHOLDER = Gene::Types::Symbol.new('_')
  %W(
    NS
    CLASS PROP METHOD NEW INIT CAST
    MODULE INCLUDE
    EXTEND SUPER
    SELF WITH
    SCOPE
    FN FNX FNXX BIND
    RETURN
    CALL DO
    VAR
    ASPECT BEFORE AFTER WHEN CONTINUE
    IMPORT EXPORT FROM
    PUBLIC PRIVATE
    IF IF_NOT ELSE
    FOR LOOP
    THROW CATCH
    BREAK
    PRINT PRINTLN
    ASSERT DEBUG
    NOOP
  ).each do |name|
    const_set name, Gene::Types::Symbol.new("#{name.downcase.gsub('_', '-')}")
  end

  BINARY_OPERATORS = [
    Gene::Types::Symbol.new('=='),
    Gene::Types::Symbol.new('!='),
    Gene::Types::Symbol.new('>'),
    Gene::Types::Symbol.new('>='),
    Gene::Types::Symbol.new('<'),
    Gene::Types::Symbol.new('<='),

    Gene::Types::Symbol.new('+'),
    Gene::Types::Symbol.new('-'),
    Gene::Types::Symbol.new('*'),
    Gene::Types::Symbol.new('/'),

    Gene::Types::Symbol.new('&&'),
    Gene::Types::Symbol.new('||'),
  ]

  class DefaultHandler
    def call context, data
      if data.is_a? Gene::Types::Base
        if VAR === data
          if data.data.length == 1
            "$context.var_(\"#{data.data[0]}\");"
          else
            "$context.var_(\"#{data.data[0]}\", #{context.process(data.data[1])});"
          end
        elsif BINARY_OPERATORS.include?(data.data[0])
          op    = data.data[0].name
          left  = context.process(data.type)
          right = context.process(data.data[1])
          "#{left} #{op} #{right}"
        end
      elsif data.is_a? Gene::Types::Stream
        result = "var $result;\n"
        result << data[0..-2].map {|item|
          "#{context.process(item)}\n"
        }.join
        result << "$result = " << context.process(data.last)
        result << "return $result;\n"
      elsif data.is_a?(::Array) and not data.is_a?(Gene::Lang::Array)
        result = Gene::Lang::Array.new
        data.each do |item|
          result.push context.process(item)
        end
        result
      elsif data.is_a?(Hash) and not data.is_a?(Gene::Lang::Hash)
        result = Gene::Lang::Hash.new
        data.each do |key, value|
          result[key] = context.process value
        end
        result
      elsif data == PLACEHOLDER or data == NOOP
        Gene::UNDEFINED
      elsif data == BREAK
        Gene::Lang::BreakValue.new
      elsif data == RETURN
        result = Gene::Lang::ReturnValue.new
        result
      # elsif data == APPLICATION
      #   context.application
      # elsif data == CONTEXT
      #   context
      # elsif data == GLOBAL
      #   context.application.global_namespace
      # elsif data == CURRENT_SCOPE
      #   context.scope
      elsif data == SELF
        context.self
      elsif data.is_a? Gene::Types::Symbol
        "$context.get('#{data}')"
      else
        # literals
        data.inspect
      end
    end
  end
end
