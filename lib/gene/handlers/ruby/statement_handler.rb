module Gene
  module Handlers
    module Ruby
      class StatementHandler < Base
        def call group
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

