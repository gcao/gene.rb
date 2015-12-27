module Gene
  module Handlers
    module Js
      class ObjectHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Hash

          @logger.debug('call', data)

          res = "{\n"
          res << data.map{|key, value| "\"#{key}\": #{context.handle_partial(value)}" }.join(',')
          res << "}\n"
        end
      end
    end
  end
end
