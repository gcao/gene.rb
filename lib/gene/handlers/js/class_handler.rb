module Gene
  module Handlers
    module Js
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

<<-JS
class #{class_name}(){
}; #{class_name};
JS
        end
      end
    end
  end
end

