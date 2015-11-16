module Gene
  module Handlers
    module Ruby
      class AssignmentHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED if group.rest.first.to_s != '='

          @logger.debug('call', group)

          left  = group.first
          right = group.rest[1..-1].map do |item|
            if item.is_a? Gene::Types::Group
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

