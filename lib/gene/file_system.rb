module Gene
  class FileSystem < Interpreter
    require 'gene/file_system/dir_handler'
    require 'gene/file_system/file_handler'

    attr :root

    def initialize
      super
      @root = Dir.mktmpdir 'gene'
    end

    def self.read dir_or_file
      # Create a new instance and generate data structure
    end

    def write root
    end
  end
end

