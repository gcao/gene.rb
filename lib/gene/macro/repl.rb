require "readline"

class Gene::Macro::Repl
  def initialize
    @interpreter = Gene::Macro::Interpreter.new
    # Define _ on the interpreter to save last result
    @interpreter.class.send :attr_accessor, :_
  end

  def start
    while input = Readline.readline("GM> ", true)
      begin
        if input =~ /^_/
          @interpreter._ = @interpreter.instance_eval(input)
        elsif input.strip == 'exit'
          puts "Exiting..."
          puts
          break
        elsif input.strip.empty?
          next
        elsif input =~ /^(self)?\.(.*)$/
          @interpreter._ = @interpreter.instance_eval("self.#{$2}")
        else
          @interpreter._ = @interpreter.parse_and_process input
        end

        p @interpreter._
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
