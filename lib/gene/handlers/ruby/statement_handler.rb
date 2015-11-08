module Gene
  module Handlers
    module Ruby
      class StatementHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          @logger.debug('call', group)
          
          if group.is_a? Gene::Types::Group
            group.to_s
          else
            group
          end
        end
      end
    end
  end
end

