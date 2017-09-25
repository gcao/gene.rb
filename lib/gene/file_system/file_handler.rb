class Gene::FileSystem::FileHandler

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == Gene::FileSystem::FILE

    @logger.debug('call', data)

    dir  = context.current_dir
    name = data.data.shift

    if name.is_a? Gene::Types::Symbol
      name = name.name
    end

    path = "#{dir}/#{name}"
    file = File.new(path, 'w')
    file.write data
    path
  end

end
