require "readline"

class Gene::Lang::Repl
  def initialize
    @interpreter = Gene::Lang::Interpreter.new
    # Define _ on the interpreter to save last result
    @interpreter.class.send :attr_accessor, :_
  end

  def start
    while input = Readline.readline("GL> ", true)
      begin
        if input.strip == 'exit'
          puts "Exiting..."
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
          @interpreter._ = @interpreter.parse_and_process input
          p @interpreter._
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
