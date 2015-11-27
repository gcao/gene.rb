module Gene
  module Handlers
    module Js
      class InvocationHandler
        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          if group.first.is_a?(Gene::Types::Ident) and group.first.name =~ /^\./
            @logger.debug('call', group)
            res = group.first[1..-1]
            res << "("
            res << group.rest.map{|item| context.handle_partial(item) }.join(', ')
            res << ")"
          elsif group[1].is_a?(Gene::Types::Ident) and group[1].name =~ /^\./
            @logger.debug('call', group)
            res = context.handle_partial(group.first).to_s
            res << group[1].to_s
            res << "("
            res << group[2..-1].map{|item| context.handle_partial(item) }.join(', ')
            res << ")"
          else
            NOT_HANDLED
          end
        end
      end
    end
  end
end

