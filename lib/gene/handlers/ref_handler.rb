module Gene
  module Handlers
    class RefHandler
      SET = Gene::Types::Ident.new('#SET')

      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        # TODO
        return Gene::NOT_HANDLED

        return context.references[data.name] if data.is_a? Gene::Types::Ref
        return context.references[data.first.name] unless data.is_a? Gene::Types::Group and data.first.is_a? Gene::Types::Ref

        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group and data.first == SET

        @logger.debug('call', data)

        data.shift
        key = data.shift.name
        value = data.shift
        context.references[key] = value

        if data.rest.length > 0
          data.first
        else
          value
        end
      end
    end
  end
end
