require "readline"

class Gene::ParserRepl
  attr_accessor :_

  def start
    while input = Readline.readline("GM> ", true)
      begin
        if input =~ /^_/
          @_ = instance_eval(input)
        elsif input.strip == 'exit'
          puts "Exiting..."
          puts
          break
        elsif input.strip.empty?
          next
        else
          @_ = Gene::Parser.parse input
        end

        p @_
        puts
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
