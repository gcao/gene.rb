require "readline"

class Gene::ParserRepl
  attr_accessor :_

  def start
    saved_input = ""

    puts "<<<   WELCOME TO GENE PARSER   >>>"
    while input = Readline.readline("Gene> ", true)
      begin
        if input.strip == 'exit'
          puts "Exiting..."
          puts "<<<         GOOD BYE         >>>"
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
          saved_input << input
          @_ = Gene::Parser.parse saved_input

          # Reset saved input
          saved_input = ""
          p @_
          puts
        end
      rescue Gene::PrematureEndError
        # Do not fail when input is not complete
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
