require "readline"

class Gene::Lang::Repl
  def initialize context = nil
    if context
      @context = context
    else
      application = Gene::Lang::Application.new
      @context = application.root_context
    end

    @context.interpreter.load_core_libs
    # Define _ on the context to save last result
    @context.class.send :attr_accessor, :_
  end

  def start
    puts "<<<   WELCOME TO GENE LANG   >>>"
    while input = Readline.readline("GL> ", true)
      begin
        if input.strip == 'exit'
          puts "Exiting..."
          puts "<<<         GOOD BYE         >>>"
          puts
          break
        elsif input.strip.empty?
          # Do nothing
        elsif input =~ /^ /  # eval code but don't change last returned value
          result = @context.instance_eval(input)
          p result
          puts
        elsif input =~ /^_/  # eval code and store returned value to _
          @context._ = @context.instance_eval(input)
          p @context._
          puts
        else # treat input as glang code, parse and execute, store result in _
          parsed = Gene::Parser.parse input
          @context._ = @context.process parsed
          p @context._
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
