module Gene
  module Handlers
    class MethodHandler < Base
      METHOD = Entity.new 'def'

      def call group
        @logger.debug('call', group)
        return NOT_HANDLED unless group.first == METHOD

        group.children.shift

        method_name = group.children.shift.name

        args = []
        args << group.children.shift if group.children.size > 1

        "(def #{method_name}(#{args.join(',')})\n#{group.children.map{|item| interpreter.handle_partial(item)}.join("\n")}\nend;)"
      end
    end
  end
end

