module Gene
  module Handlers
    module Js
      class LiteralHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, item
          case item
          when String, Integer, Fixnum, true, false
            @logger.debug('call', item)
            item.inspect
          when nil
            @logger.debug('call', item)
            "null"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end

