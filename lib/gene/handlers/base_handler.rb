module Gene
  module Handlers
    class BaseHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base

        return Gene::NOOP if data.type == nil

        #@logger.debug binding.send(:caller).join("\n")
        @logger.debug('call', data)

        # TODO detect whether first item has changed, if yes, re-handle this data

        begin
          context.stack.push data

          (data.data.size - 1).downto 0 do |i|
            if i > 0 and data.data[i-1] == Gene::COMMENT_NEXT
              data.data.delete_at i
            elsif [Gene::COMMENT_NEXT, Gene::NOOP].include? data.data[i]
              data.data.delete_at i
            else
              data.data[i] = context.handle_partial(data.data[i])
            end
          end
        ensure
          context.stack.pop
        end

        NOT_HANDLED
      end
    end
  end
end
