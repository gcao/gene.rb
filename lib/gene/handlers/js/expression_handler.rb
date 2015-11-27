module Gene
  module Handlers
    module Js
      class ExpressionHandler

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          @logger.debug('call', group)

          if group.rest.find{ |item| item.is_a? Gene::Types::Ident and item.to_s =~ /^[!<>+\-*\/=]+$/ }
            "(#{group.map{|item| context.handle_partial(item) }.join(' ')})"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end


