module Gene
  module Handlers
    module Ruby
      class ComplexStringHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::ComplexString

          @logger.debug('call', data)

          data.map do |item|
            item.inspect + ".to_s"
          end.join(' + ')
        end
      end
    end
  end
end

