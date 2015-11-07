module Gene
  class FileSystem < Interpreter
    DIR  = Gene::Types::Ident.new('dir')
    FILE = Gene::Types::Ident.new('file')

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
      if File.directory? dir_or_file
        data = Gene::Types::Group.new(DIR, File.basename(dir_or_file))
        Dir["#{dir_or_file}/*"].each do |file|
          data.push read(file)
        end
        data
      elsif File.file? dir_or_file
        Gene::Types::Group.new(FILE, File.basename(dir_or_file), File.read(dir_or_file))
      else
        raise "#{self.class}.read(#{dir_or_file.inspect}): NOT FOUND."
      end
    end

    def self.write dir, data
      if data.is_a? Gene::Types::Group
        if data.first == Gene::FileSystem::DIR
          path = "#{dir}/#{data[1]}"
          Dir.mkdir path
          data[2..-1].each do |item|
            write path, item
          end
        elsif data.first == Gene::FileSystem::FILE
          File.open "#{dir}/#{data[1]}", 'w' do |file|
            file.write data[2]
          end
        else
          raise "#{self.class}.write: NOT SUPPORTED ."
        end
      end
    end
  end
end

