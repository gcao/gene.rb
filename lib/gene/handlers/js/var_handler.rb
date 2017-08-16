module Gene
  module Handlers
    module Js
      class VarHandler
        VAR = Gene::Types::Ident.new('var')

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == VAR

          @logger.debug('call', data)

          data.map{|item| context.handle_partial(item) }.join(' ') + ";\n"
        end
      end
    end
  end
end

