class Gene::FileSystem::DirHandler

  def initialize
    @logger = Logem::Logger.new(self)
  end

  def call context, data
    return Gene::NOT_HANDLED unless data.is_a? Gene::Types::Base and data.type == Gene::FileSystem::DIR

    @logger.debug('call', data)

    name = data[1]
    name = context.handle_data name if name.is_a? Gene::Types::Base

    dir = "#{context.root}/#{name}"
    Dir.mkdir dir
    context.dirs.push dir

    begin
      data[2..-1].each do |child|
        context.handle_partial child
      end
    ensure
      context.dirs.pop
    end

    dir
  end

end
