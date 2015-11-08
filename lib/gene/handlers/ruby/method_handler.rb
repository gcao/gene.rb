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

          args = group.size > 1 ? group.shift : []

<<-RUBY
def #{method_name}(#{args.is_a?(Array) ? args.join(',') : args})
#{
group.map{|item|
  if item.is_a? Gene::Types::Group
    context.handle_partial(item)
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

