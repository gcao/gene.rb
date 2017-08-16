module Gene
  module Handlers
    module Ruby
      class AssignmentHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.rest.first.to_s == '='

          @logger.debug('call', data)

          left  = data.first
          right = data.rest[1..-1].map do |item|
            if item.is_a? Gene::Types::Base
              # TODO
            else
              item.inspect
            end
          end
          "#{left} = (#{right.join(' ')})"
        end
      end
    end
  end
end

