module Gene
  class Interpreter
    def initialize
      @logger = Logem::Logger.new(self)
      @context = Context.new(self)
      @handlers = [
        Handler.new
      ]
    end

    def run data
      handle_partial data
    end

    def handle_partial data
      @logger.debug('handle_special', data.inspect)
      case data
      when Group
        handle_group data

      when Entity
        data

      when Array
        handle_array data

      #when Hash
      #  data

      else
        data

      end
    end

    def handle_group group
      @logger.debug('handle_group', group.inspect)
      return NOOP if group.children.empty?

      case group.first
      when NOOP
        group.children.shift
        handle_group group

      when ARRAY
        handle_array group.rest

      when HASH
        Hash[*group.rest]

      else
        @handlers.each do |handler|
          result = handler.call group
          next if result == NOT_HANDLED
          break handle_partial(result)
        end
      end
    end

    def handle_array array
      @logger.debug('handle_array', array.inspect)
      result = []
      array.each do |child| 
        next if child == NOOP

        value = handle_partial(child)
        result << value if value != NOOP
      end
      result
    end
  end
end

