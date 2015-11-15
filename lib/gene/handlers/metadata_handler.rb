module Gene
  module Handlers
    class MetadataHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first.to_s =~ /^\^.+/

        @logger.debug('call', group)

        # TODO add metadata to parent group object
        # Or wrap parent with a data type called DataWithMeta
        # Built-in types (literals, arrays, hashes etc) don't support metadata?

        if context.parent and context.parent.respond_to?(:metadata)
          key   = group.first.to_s[1..-1]
          value = group.length == 1 ? true : group[1]
          context.parent.metadata[key] = value
        else
          raise context.parent
        end
      end
    end
  end
end
