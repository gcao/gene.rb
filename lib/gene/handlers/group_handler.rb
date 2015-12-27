module Gene
  module Handlers
    class GroupHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group

        return Gene::NOOP if data.length == 0

        #@logger.debug binding.send(:caller).join("\n")
        @logger.debug('call', data)

        # TODO detect whether first item has changed, if yes, re-handle this data

        begin
          context.stack.push data

          data.each_with_index do |child, i|
            next if child == Gene::NOOP

            data[i] = context.handle_partial(child)
          end
        ensure
          context.stack.pop
        end

        NOT_HANDLED
      end
    end
  end
end
