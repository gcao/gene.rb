module Gene
  module Handlers
    module Ruby
      class ClassHandler
        CLASS = Gene::Types::Ident.new 'class'

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == CLASS

          @logger.debug('call', data)

          class_name = data.data.shift.name
<<-RUBY
class #{class_name}

#{data.data.map{|item| context.handle_partial(item) }.join("\n")}

end; #{class_name}
RUBY
        end
      end
    end
  end
end

