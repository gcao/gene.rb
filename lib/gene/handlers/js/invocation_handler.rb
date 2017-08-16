module Gene
  module Handlers
    module Js
      class InvocationHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return NOT_HANDLED unless data.is_a? Gene::Types::Base

          if data.type.is_a?(Gene::Types::Ident) and data.type.name =~ /^\./
            @logger.debug('call', data)
            res = data.type.name[1..-1]
            res << "("
            res << data.data.map{|item| context.handle_partial(item) }.join(', ')
            res << ")"
          elsif data.data[0].is_a?(Gene::Types::Ident) and data.data[0].name =~ /^\./
            @logger.debug('call', data)
            res = context.handle_partial(data.type).to_s
            res << data.data[0].to_s
            res << "("
            res << data.data[1..-1].map{|item| context.handle_partial(item) }.join(', ')
            res << ")"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end

