module Gene
  module Handlers
    module Js
      class LiteralHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          case data
          when String, Integer, Fixnum, true, false
            @logger.debug('call', data)
            data.inspect
          when nil
            @logger.debug('call', data)
            "null"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end

