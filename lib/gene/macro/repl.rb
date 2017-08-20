class Gene::Macro::Repl
  attr_reader :interpreter
  attr_accessor :_

  def initialize
    @interpreter = Gene::Macro::Interpreter.new
  end

  def start
    loop do
      begin
        print "MACRO> "

        input = gets.chomp
        if input =~ /^_/
          p instance_eval(input)
        else
          self._ = @interpreter.parse_and_process input
          puts self._
        end
      rescue
        puts "#{$!.class}: #{$!}"
        puts $!.backtrace.map{|line| "\t#{line}" }.join("\n")
      rescue RuntimeError
        puts "#{$!.class}: #{$!}"
        puts $!.backtrace.map{|line| "\t#{line}" }.join("\n")
      ensure
        puts
      end
    end
  end
end
