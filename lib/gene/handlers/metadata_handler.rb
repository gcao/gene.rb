module Gene
  module Handlers
    class MetadataHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, group
        return Gene::NOT_HANDLED unless group.first.to_s =~ /^\^/

        @logger.debug('call', group)

        # TODO add metadata to parent group object
        # Or wrap parent with a data type called DataWithMeta
        # Built-in types (literals, arrays, hashes etc) don't support metadata?
      end
    end
  end
end
