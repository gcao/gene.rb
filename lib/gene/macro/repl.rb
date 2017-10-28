require "readline"

class Gene::Macro::Repl
  def initialize
    @interpreter = Gene::Macro::Interpreter.new
    # Define _ on the interpreter to save last result
    @interpreter.class.send :attr_accessor, :_
  end

  def start
    saved_input = ""

    puts "<<<   WELCOME TO GENE MACROS   >>>"
    while input = Readline.readline("GM> ", true)
      begin
        if input.strip == 'exit'
          puts "Exiting..."
          puts "<<<         GOOD BYE         >>>"
          puts
          break
        elsif input.strip.empty?
          # Do nothing
        elsif input =~ /^ /
          result = @interpreter.instance_eval(input)
          p result
          puts
        elsif input =~ /^_/
          @interpreter._ = @interpreter.instance_eval(input)
          p @interpreter._
          puts
        else
          saved_input << input
          @interpreter._ = @interpreter.parse_and_process saved_input

          # Reset saved input
          saved_input = ""
          p @interpreter._
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
