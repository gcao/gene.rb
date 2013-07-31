module Gene
  module Handlers
    class ClassHandler < Base
      CLASS = Entity.new 'class'

      def call group
        @logger.debug('call', group)
        return NOT_HANDLED unless group.first == CLASS

        group.children.shift

        class_name = group.children.shift.name
        "(class #{class_name}\n#{group.children.map{|item| interpreter.handle_partial(item)}.join("\n")}\nend; #{class_name})"
      end
    end
  end
end

