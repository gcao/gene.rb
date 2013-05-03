module Gene
  class Group
    attr :data

    def initialize *data
      @data = data
    end

    def == other
      return unless other.is_a? Group

      data == other.data
    end
  end
end
