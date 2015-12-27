module Gene
  module Handlers
    class RegexpHandler
      def initialize
        @logger = Logem::Logger.new(self)
      end

      def call context, data
        return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Group and
                                        data.first.is_a? Gene::Types::Ident and
                                        data.first.to_s =~ %r(^#//([a-z]*))

        @logger.debug('call', data)

        matched = $1 || ""

        flags = 0
        flags |= Regexp::IGNORECASE if matched.index('i')
        flags |= Regexp::MULTILINE  if matched.index('m')
        flags |= Regexp::EXTENDED   if matched.index('x')

        Regexp.new data.rest.map(&:to_s).join, flags
      end
    end
  end
end
