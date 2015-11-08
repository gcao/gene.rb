module Gene
  module Handlers
    module Ruby
      class ClassHandler
        CLASS = Gene::Types::Ident.new 'class'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED unless group.first == CLASS

          @logger.debug('call', group)

          group.shift

          class_name = group.shift.name
<<-RUBY
class #{class_name}

#{group.map{|item| context.handle_partial(item) }.join}

end; #{class_name}
RUBY
        end
      end
    end
  end
end

