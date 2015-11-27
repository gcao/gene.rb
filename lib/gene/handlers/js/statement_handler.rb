module Gene
  module Handlers
    module Js
      class StatementHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          @logger.debug('call', group)

          return Gene::NOT_HANDLED unless group.is_a? Gene::Types::Group

          group.join(' ') + ";\n"
        end
      end
    end
  end
end

