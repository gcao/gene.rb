module Gene
  module Handlers
    class RefHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return context.references[data.name] if data.is_a? Gene::Types::Ref

        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group and data.first.is_a? Gene::Types::Ref

        @logger.debug('call', data)

        key = data.first.name

        if data.rest.length == 0
          context.references[key]
        else
          value = data.rest[0]
          context.references[key] = value

          if data.rest.length == 2
            data.rest[1]
          else
            value
          end
        end
      end
    end
  end
end
