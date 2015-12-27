module Gene
  module Handlers
    module Js
      class ExpressionHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return NOT_HANDLED unless data.is_a? Gene::Types::Group

          @logger.debug('call', data)

          if data.rest.find{ |item| item.is_a? Gene::Types::Ident and item.to_s =~ /^[!<>+\-*\/=]+$/ }
            "(#{data.map{|item| context.handle_partial(item) }.join(' ')})"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end


