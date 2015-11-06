class Gene::FileSystem::FileHandler < Gene::Handlers::Base
  FILE = Gene::Entity.new('file')

  def initialize(interpreter)
    super interpreter
    @logger = Logem::Logger.new(self)
  end

  def call group
    @logger.debug('call', group)
    return Gene::NOT_HANDLED unless group.first.is_a? Gene::Entity and group.first == FILE

    group.shift

    dir  = interpreter.current_dir
    name = group.shift

    if name.is_a? Gene::Entity
      name = name.name
    end

    path = "#{dir}/#{name}"
    file = File.new(path, 'w')
    file.write group
    path
  end

end
