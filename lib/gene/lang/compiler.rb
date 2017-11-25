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
  end

  def process data
    result = nil
  end

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

  class DefaultHandler
    def call context, data
      if data.is_a? Gene::Types::Base
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
      elsif data == APPLICATION
        context.application
      elsif data == CONTEXT
        context
      elsif data == GLOBAL
        context.application.global_namespace
      elsif data == CURRENT_SCOPE
        context.scope
      elsif data == SELF
        context.self
      elsif data.is_a? Gene::Types::Symbol
        name = data.name
      else
        # literals
        data
      end
    end
  end
end
