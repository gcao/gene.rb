module Gene
  module Handlers
    module Ruby
      class MethodHandler < Base
        METHOD = Entity.new 'def'

        def call group
          @logger.debug('call', group)
          return NOT_HANDLED unless group.first == METHOD

          group.shift

          method_name = group.shift.name

          args = []
          if group.size > 1
            item = group.shift
            if item.is_a? Group
              args.concat item.rest
            else
              args << item
            end
          end

          "(def #{method_name}(#{args.join(',')})\n#{group.map{|item| interpreter.handle_partial(item)}.join("\n")}\nend;)"
        end
      end
    end
  end
end

