require "some_lib"

class A
  def initialize a, *b
    puts "initialize"
  end
end

__END__
(require "some_lib")
(class A
 (def initialize[a *b]
  (puts "initialize")
 )
)
