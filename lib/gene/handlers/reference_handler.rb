module Gene
  module Handlers
    class ReferenceHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first.to_s =~ /^#.+/

        @logger.debug('call', group)

        key = group.first.to_s[1..-1]

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
