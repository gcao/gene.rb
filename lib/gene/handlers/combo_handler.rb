module Gene
  module Handlers
    class ComboHandler
      HandlerWithPriority = Struct.new(:handler, :priority)

      def initialize
        @logger = Logem::Logger.new(self)
        @handlers_with_priority = []
        @handlers = []
      end

      def add handler, priority
        insert_position = @handlers_with_priority.length
        @handlers_with_priority.each_with_index do |item, i|
          if item.priority > priority
            insert_position = i
          end
        end

        @handlers_with_priority.insert insert_position, HandlerWithPriority.new(handler, priority)
        @handlers = @handlers_with_priority.map &:handler
      end

      def call context, data
        result = NOT_HANDLED

        @handlers.each do |handler|
          result = handler.call context, data
          break result if result != NOT_HANDLED
        end

        result
      end
    end
  end
end
