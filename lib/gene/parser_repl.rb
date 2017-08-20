require "readline"

class Gene::ParserRepl
  attr_accessor :_

  def start
    while input = Readline.readline("Gene> ", true)
      begin
        if input.strip == 'exit'
          puts "Exiting..."
          puts
          break
        elsif input.strip.empty?
          # Do nothing
        elsif input =~ /^ /
          result = instance_eval(input)
          p result
          puts
        elsif input =~ /^_/
          @_ = instance_eval(input)
          p @_
          puts
        else
          @_ = Gene::Parser.parse input
          p @_
          puts
        end
      rescue
        puts "#{$!.class}: #{$!}"
        puts $!.backtrace.map{|line| "\t#{line}" }.join("\n")
        puts
      rescue RuntimeError
        puts "#{$!.class}: #{$!}"
        puts $!.backtrace.map{|line| "\t#{line}" }.join("\n")
        puts
      end
    end
  end
end
