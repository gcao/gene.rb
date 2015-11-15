module Gene
  module Handlers
    class ReferenceHandler
      REF = Gene::Types::Ident.new('@')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first == REF

        @logger.debug('call', group)

        if group.rest.length == 1
          context.references[group.rest.first.to_s]
        else
          key   = group.rest.first.to_s
          value = group.rest[1]
          context.references[key] = value

          if group.rest.length == 3
            group.rest[2]
          else
            value
          end
        end
      end
    end
  end
end
