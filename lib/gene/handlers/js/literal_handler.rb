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
          #when Array
          #  item.map {|i| context.handle_partial(i) }
          when Hash
            p item
            pairs = item.keys.map {|key,| "\"#{key}\": #{context.handle_partial(item[key])}" }
            "{#{pairs.join", "}}"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end

