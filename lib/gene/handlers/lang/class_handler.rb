module Gene
  module Handlers
    module Lang
      class ClassHandler
        CLASS = Gene::Types::Ident.new('class')

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, data
          if data.is_a? Gene::Types::Group and data.first == CLASS
            Gene::Lang::Class.new data[1].to_s
          else
            Gene::NOT_HANDLED
          end
        end
      end
    end
  end
end
