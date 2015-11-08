class Gene::FileSystem::DirHandler

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, group
    return Gene::NOT_HANDLED unless group.first == Gene::FileSystem::DIR

    @logger.debug('call', group)

    name = group[1]
    name = context.handle_group name if name.is_a? Gene::Types::Group

    dir = "#{context.root}/#{name}"
    Dir.mkdir dir
    context.dirs.push dir

    begin
      group[2..-1].each do |child|
        context.handle_partial child
      end
    ensure
      context.dirs.pop
    end

    dir
  end

end
