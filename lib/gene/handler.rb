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

      when Entity

      else
        if group.children.size == 1
          group.children.first
        else
          group.children
        end
      end
    end
  end
end

