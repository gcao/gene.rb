module Gene
  module Handlers
    module Js
      class ObjectHandler
        HASH = Gene::Types::Ident.new('{}')

        def initialize
          @logger = Logem::Logger.new(self)
        end

        def call context, group
          return Gene::NOT_HANDLED unless group.first == HASH

          @logger.debug('call', group)

          # Ignore pairs whose key or value is ()
          pairs = group.rest.reject do |pair|
            pair.first == Gene::NOOP or pair.second == Gene::NOOP
          end

          obj = Hash[*pairs.reduce([]){|result, pair| result << context.handle_partial(pair.first) << context.handle_partial(pair.second) }]

          res = "{\n"
          obj.each do |key, value|
            res << "\"#{key}\": #{value}, "
          end
          res << "}\n"
        end
      end
    end
  end
end
