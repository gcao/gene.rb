class Gene::FileSystem::FileHandler < Gene::Handlers::Base
  FILE = Gene::Entity.new('file')

  def initialize(interpreter)
    super interpreter
    @logger = Logem::Logger.new(self)
  end

  def call group
    @logger.debug('call', group)
    return Gene::NOT_HANDLED unless group.first.is_a? Gene::Entity and group.first == FILE

    "#{self.class}: TODO"
  end

end
