module Gene
  module Handlers
    class ClassHandler < Base
      def call group
        @logger.debug('call', group)
        return NOT_HANDLED unless group.first.is_a? Entity and group.first.name == 'class'

        group.children.shift

        class_name = group.children.shift.name
        context.instance_eval "(class #{class_name}\n#TODO\nend; #{class_name})"
      end
    end
  end
end

