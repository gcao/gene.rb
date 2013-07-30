module Gene
  class Interpreter
    attr :context

    def initialize
      @logger = Logem::Logger.new(self)
      @context = Context.new(self)
    end

    def handlers= value
      @handlers = value
    end

    def run data
      handle_partial data
    end

    private

    def handle_partial data
      @logger.debug('handle_special', data.inspect)

      self.class.normalize data

      case data
      when Group
        handle_group data

      when Array
        handle_array data

      when Entity
        data

      else
        data

      end
    end

    def handle_group group
      @logger.debug('handle_group', group.inspect)

      case group.first
      when ARRAY
        handle_array group.rest

      when HASH
        Hash[*group.rest.reduce([]){|result, pair| result << pair.first << pair.second }]

      else
        handled = false
        result = @handlers.each do |handler|
          result = handler.call group
          next if result == NOT_HANDLED

          handled = true
          break handle_partial(result)
        end
        if handled
          result
        else
          group
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

    def self.normalize group_or_array
      case group_or_array
      when Group
        group_or_array.children.reject!{|child| child == NOOP }
      when Array
        group_or_array.reject!{|item| item == NOOP }
      end

      group_or_array
    end
  end
end

