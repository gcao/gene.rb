module Gene
  module Handlers
    module Ruby
      class StatementHandler < Base
        def call group
          @logger.debug('call', group)

          statement = group.to_s
          statement
        end
      end
    end
  end
end

