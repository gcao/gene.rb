module Gene
  module Handlers
    module Js
      class InvocationHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return NOT_HANDLED unless data.is_a? Gene::Types::Group

          if data.first.is_a?(Gene::Types::Ident) and data.first.name =~ /^\./
            @logger.debug('call', data)
            res = data.first[1..-1]
            res << "("
            res << data.rest.map{|item| context.handle_partial(item) }.join(', ')
            res << ")"
          elsif data[1].is_a?(Gene::Types::Ident) and data[1].name =~ /^\./
            @logger.debug('call', data)
            res = context.handle_partial(data.first).to_s
            res << data[1].to_s
            res << "("
            res << data[2..-1].map{|item| context.handle_partial(item) }.join(', ')
            res << ")"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end

