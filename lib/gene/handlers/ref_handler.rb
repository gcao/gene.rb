module Gene
  module Handlers
    class RefHandler
      SET   = Gene::Types::Ident.new('#SET')
      UNSET = Gene::Types::Ident.new('#UNSET')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        if data.is_a? Gene::Types::Ref
          context.references[data.name]

        elsif data.is_a? Gene::Types::Base and data.type == SET
          @logger.debug('call', data)

          data.shift
          key = data.shift.name
          value = data.shift
          context.references[key] = value

          if data.length > 0
            data.last
          else
            value
          end

        elsif data.is_a? Gene::Types::Base and data.type == UNSET
          @logger.debug('call', data)

          data.shift
          key = data.shift.name
          context.references.delete(key)
          Gene::NOOP

        else
          Gene::NOT_HANDLED
        end
      end
    end
  end
end
