class Gene::FileSystem::DirHandler < Gene::Handlers::Base
  DIR = Gene::Entity.new('dir')

  def initialize(interpreter)
    super interpreter
    @logger = Logem::Logger.new(self)
  end

  def call group
    @logger.debug('call', group)
    return Gene::NOT_HANDLED unless group.first.is_a? Gene::Entity and group.first == DIR

    "#{self.class}: TODO"
  end

end
