module Gene
  module Handlers
    class RefHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first.is_a? Gene::Types::Ref

        @logger.debug('call', group)

        key = group.first.name

        if group.rest.length == 0
          context.references[key]
        else
          value = group.rest[0]
          context.references[key] = value

          if group.rest.length == 2
            group.rest[1]
          else
            value
          end
        end
      end
    end
  end
end
