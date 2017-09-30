module M
  def test
    puts "M.test"
    super
  end
end

module N
  include M
  def test
    puts "N.test"
    super
  end
end

module O
  def test
    puts "O.test"
    super
  end
end

class A
  def test
    puts "A.test"
  end
end

class B < A
  include N
  include O
  def test
    puts "B.test"
    super
  end
end

b = B.new
b.test
