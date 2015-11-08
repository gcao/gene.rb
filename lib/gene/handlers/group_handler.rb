module Gene
  module Handlers
    class GroupHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        @logger.debug binding.send(:caller).join("\n")
        @logger.debug('call', group)

        # TODO detect whether first item has changed, if yes, re-handle this group

        group.each_with_index do |child, i|
          next if child == Gene::NOOP

          group[i] = context.handle_partial(child)
        end

        NOT_HANDLED
      end
    end
  end
end
