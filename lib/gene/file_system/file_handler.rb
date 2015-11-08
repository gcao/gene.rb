class Gene::FileSystem::FileHandler

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, group
    return Gene::NOT_HANDLED unless group.first == Gene::FileSystem::FILE

    @logger.debug('call', group)

    group.shift

    dir  = context.current_dir
    name = group.shift

    if name.is_a? Gene::Types::Ident
      name = name.name
    end

    path = "#{dir}/#{name}"
    file = File.new(path, 'w')
    file.write group
    path
  end

end
