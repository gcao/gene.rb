module Gene
  module Handlers
    module Ruby
      class ClassHandler < Base
        CLASS = Gene::Types::Ident.new 'class'

        def call group
          @logger.debug('call', group)
          return Gene::NOT_HANDLED unless group.first == CLASS

          group.shift

          class_name = group.shift.name
<<-RUBY
class #{class_name}

#{group.map{|item| interpreter.handle_partial(item) }.join}

end; #{class_name}
RUBY
        end
      end
    end
  end
end

