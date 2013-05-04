module Gene
  NOT_HANDLED = Object.new

  class Handler
    LET = Entity.new('let')

    def initialize
      @logger = Logem::Logger.new(self)
    end

    def call group
      @logger.debug('call', group)
      return NOT_HANDLED unless group.first.is_a? Entity and group.first.name == '$$'

      group.children.shift

      case group.first
      when LET

      else
        group
      end
    end
  end
end

