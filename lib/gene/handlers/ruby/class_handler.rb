module Gene
  module Handlers
    module Ruby
      class ClassHandler < Base
        CLASS = Entity.new 'class'

        def call group
          @logger.debug('call', group)
          return NOT_HANDLED unless group.first == CLASS

          group.shift

          class_name = group.shift.name
          "(class #{class_name}\n#{group.map{|item| interpreter.handle_partial(item)}.join("\n")}\nend; #{class_name})"
        end
      end
    end
  end
end

