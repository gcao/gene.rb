class Gene::ParserRepl
  attr_accessor :_

  def start
    loop do
      begin
        print "GENE> "

        input = gets.chomp
        if input =~ /^_/
          p instance_eval(input)
        else
          self._ = Gene::Parser.parse input
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
