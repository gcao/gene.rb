module Gene
  NOT_HANDLED = Object.new

  class Handler
    def call group
      return NOT_HANDLED unless group.first.is_a? Entity and group.first.name == '$$'

      group.children.shift

      case group.first
      when Entity
      else
        if group.rest.size == 1
          group.rest.first
        else
          group.rest
        end
      end
    end
  end
end

