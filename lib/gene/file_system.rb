module Gene
  class FileSystem < AbstractInterpreter
    DIR  = Gene::Types::Symbol.new('dir')
    FILE = Gene::Types::Symbol.new('file')

    require 'gene/file_system/dir_handler'
    require 'gene/file_system/file_handler'

    attr :dirs

    def initialize
      super

      @handlers.add 100, Gene::FileSystem::DirHandler.new
      @handlers.add 100, Gene::FileSystem::FileHandler.new

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
      if File.directory? dir_or_file
        data = Gene::Types::Base.new(DIR, File.basename(dir_or_file))
        Dir["#{dir_or_file}/*"].each do |file|
          data.data.push read(file)
        end
        data
      elsif File.file? dir_or_file
        Gene::Types::Base.new(FILE, File.basename(dir_or_file), File.read(dir_or_file))
      else
        raise "#{self.class}.read(#{dir_or_file.inspect}): NOT FOUND."
      end
    end

    def self.write dir, data
      if data.is_a? Gene::Types::Base
        if data.type == Gene::FileSystem::DIR
          path = "#{dir}/#{data.data[0]}"
          Dir.mkdir path
          data.data[1..-1].each do |item|
            write path, item
          end
        elsif data.type == Gene::FileSystem::FILE
          File.open "#{dir}/#{data.data[0]}", 'w' do |file|
            file.write data.data[1]
          end
        else
          raise "#{self.class}.write: NOT SUPPORTED ."
        end
      end
    end
  end
end

