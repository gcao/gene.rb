module Gene
  module Handlers
    module Ruby
      class AssignmentHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED if group.rest.first.to_s !~ /=/

          @logger.debug('call', group)
          
          "#{group.first} #{group.rest.join(' ')}"
        end
      end
    end
  end
end

