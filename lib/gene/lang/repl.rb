require "readline"

class Gene::Lang::Repl
  def initialize context = nil
    if context
      @context = context
    else
      application = Gene::Lang::Application.new
      application.load_core_libs
      @context = application.create_root_context
    end

    # Define _ on the context to save last result
    @context.class.send :attr_accessor, :_
  end

  def start
    saved_input = ""

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
          saved_input << input
          parsed = Gene::Parser.parse saved_input

          # Reset saved input
          saved_input = ""
          @context._ = @context.process parsed
          p @context._
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
