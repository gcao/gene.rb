module Gene
  class FileSystem < Interpreter
    require 'gene/file_system/dir_handler'
    require 'gene/file_system/file_handler'

    attr :dirs

    def initialize
      super
      root = Dir.mktmpdir('gene')
      @dirs = [root]
    end

    def root
      @dirs.first
    end

    def current_dir
      @dirs.last
    end

    def self.read dir_or_file
      # Create a new instance and generate data structure
    end

    def write root
    end
  end
end

