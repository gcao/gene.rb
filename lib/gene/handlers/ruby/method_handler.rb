module Gene
  module Handlers
    module Ruby
      class MethodHandler
        METHOD = Gene::Types::Symbol.new 'def'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == METHOD

          @logger.debug('call', data)

          method_name = data.data.shift.name

          args = data.data.size > 1 ? data.data.shift : []
          if args.is_a? Array
            args = args.map do |arg|
              if arg.is_a? Array
                "#{arg[0]} = #{arg[1].inspect}"
              else
                arg
              end
            end.join(', ')
          end

<<-RUBY
def #{method_name}(#{args})
#{
data.data.map{|item|
  if item.is_a? Gene::Types::Base
    result = context.handle_partial(item)
    result.is_a?(String) ? result : result.inspect
  else
    item.inspect
  end
}.join("\n")
}
end
RUBY
        end
      end
    end
  end
end

