class Gene::FileSystem::DirHandler < Gene::Handlers::Base
  DIR = Gene::Entity.new('dir')

  def initialize(interpreter)
    super interpreter
    @logger = Logem::Logger.new(self)
  end

  def call group
    @logger.debug('call', group)
    return Gene::NOT_HANDLED unless group.first.is_a? Gene::Entity and group.first == DIR

    name = group[1]
    name = interpreter.handle_group name if name.is_a? Gene::Group

    dir = "#{interpreter.root}/#{name}"
    Dir.mkdir dir
    interpreter.dirs.push dir

    begin
      group[2..-1].each do |child|
        interpreter.handle_partial child
      end
    ensure
      interpreter.dirs.pop
    end

    dir
  end

end
