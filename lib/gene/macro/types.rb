module Gene::Macro
  class Ignore
    def to_s
      self.class.to_s
    end
  end
  IGNORE = Ignore.new

  class Function
  end

  class Scope < Hash
    def initialize parent
    end
  end

end
