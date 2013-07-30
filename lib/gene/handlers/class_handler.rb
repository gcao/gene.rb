module Gene
  module Handlers
    class ClassHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call group
        @logger.debug('call', group)
        return NOT_HANDLED unless group.first.is_a? Entity and group.first.name == 'class'

        group.children.shift

        class_name = group.children.shift.name
        eval "(class #{class_name}\n#TODO\nend)"
      end
    end
  end
end

