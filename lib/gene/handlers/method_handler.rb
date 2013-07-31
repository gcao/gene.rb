module Gene
  module Handlers
    class MethodHandler < Base
      METHOD = Entity.new 'def'

      def call group
        @logger.debug('call', group)
        return NOT_HANDLED unless group.first == METHOD

        group.children.shift

        method_name = group.children.shift.name
        "(def #{method_name}()\n#{group.children.map{|item| interpreter.handle_partial(item)}.join("\n")}\nend;)"
      end
    end
  end
end

