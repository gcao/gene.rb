require "readline"

class Gene::Lang::Jit::Repl
  attr :options

  def initialize options = {}
    @options = options
  end

  def start
    compiler = Gene::Lang::Jit::Compiler.new

    app = Gene::Lang::Jit::APP
    app.load_core_lib

    saved_input = ""

    puts "<<<   WELCOME TO GENE LANG   >>>"
    while input = Readline.readline("> ", true)
      begin
        if input.strip == 'exit'
          puts "Exiting..."
          puts "<<<         GOOD BYE         >>>"
          puts
          break
        elsif input.strip.empty?
          # Do nothing
        else # treat input as gene code, parse and execute, store result in $
          saved_input << input << " "
          parsed = Gene::Parser.parse saved_input

          # Reset saved input
          saved_input = ""
          mod = compiler.compile parsed
          app.last_result = app.run mod, options
          p app.last_result
          puts
        end
      rescue Gene::PrematureEndError
        # Do not fail when input is not complete
      rescue
        saved_input = ""
        puts "#{$!.class}: #{$!}"
        puts $!.backtrace.map{|line| "\t#{line}" }.join("\n")
        puts
      rescue RuntimeError
        saved_input = ""
        puts "#{$!.class}: #{$!}"
        puts $!.backtrace.map{|line| "\t#{line}" }.join("\n")
        puts
      end
    end
  end
end
