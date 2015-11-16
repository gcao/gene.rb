module Gene
  module Handlers
    module Ruby
      class MethodHandler
        METHOD = Gene::Types::Ident.new 'def'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED unless group.first == METHOD

          @logger.debug('call', group)

          group.shift

          method_name = group.shift.name

          args = group.size > 1 ? context.handle_partial(group.shift) : []
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
group.map{|item|
  if item.is_a? Gene::Types::Group
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

