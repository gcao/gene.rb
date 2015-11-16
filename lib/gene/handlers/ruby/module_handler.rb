module Gene
  module Handlers
    module Ruby
      class ModuleHandler
        MODULE = Gene::Types::Ident.new 'module'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED unless group.first == MODULE

          @logger.debug('call', group)

          group.shift

          name = group.shift.name
<<-RUBY
module #{name}

#{group.map{|item| context.handle_partial(item) }.join("\n")}

end; #{name}
RUBY
        end
      end
    end
  end
end

