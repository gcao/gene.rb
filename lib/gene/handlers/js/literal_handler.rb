module Gene
  module Handlers
    module Js
      class LiteralHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, item
          @logger.debug('call', item)

          case item
          when String, Integer, Fixnum, true, false
            item.inspect
          when nil
            "null"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end

