module Gene
  module Handlers
    class MethodHandler < Base
      METHOD = Entity.new 'def'

      def call group
        @logger.debug('call', group)
        return NOT_HANDLED unless group.first == METHOD

        group.shift

        method_name = group.shift.name

        args = []
        args << group.shift if group.size > 1

        "(def #{method_name}(#{args.join(',')})\n#{group.map{|item| interpreter.handle_partial(item)}.join("\n")}\nend;)"
      end
    end
  end
end

