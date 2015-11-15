module Gene
  module Handlers
    class MetadataHandler
      METADATA = Gene::Types::Ident.new('^')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first == METADATA

        @logger.debug('call', group)

        # TODO add metadata to parent group object
        # Or wrap parent with a data type called DataWithMeta
        # Built-in types (literals, arrays, hashes etc) don't support metadata?

        if context.parent and context.parent.respond_to?(:metadata)
          key   = group.rest[0].to_s
          value = group.length == 2 ? true : group[2]
          context.parent.metadata[key] = value
        else
          raise context.parent
        end
      end
    end
  end
end
