module Gene
  module Handlers
    module Ruby
      class ModuleHandler
        MODULE = Gene::Types::Ident.new 'module'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.first == MODULE

          @logger.debug('call', data)

          data.shift

          name = data.shift.name
<<-RUBY
module #{name}

#{data.map{|item| context.handle_partial(item) }.join("\n")}

end; #{name}
RUBY
        end
      end
    end
  end
end

