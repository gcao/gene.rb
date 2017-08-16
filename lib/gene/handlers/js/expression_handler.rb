module Gene
  module Handlers
    module Js
      class ExpressionHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return NOT_HANDLED unless data.is_a? Gene::Types::Base

          if data.data.find{ |item| item.is_a? Gene::Types::Ident and item.to_s =~ /^[!<>+\-*\/=]+$/ }
            @logger.debug('call', data)
            "(#{data.type.inspect} #{data.data.map{|item| context.handle_partial(item) }.join(' ')})"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end


