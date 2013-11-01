module Gene
  class Pair
    attr_reader :first, :second

    def initialize first, second
      @first  = first
      @second = second
    end

    def == other
      return true if other == NOOP and (first == NOOP or second == NOOP)

      return unless other.is_a? self.class

      first == other.first and second == other.second
    end

    def to_s
      "#{first} : #{second}"
    end
  end
end

__END__
(module Gene
 (class Pair
  (attr_reader :first :second)
  (def initialize[first second]
   (= @first first)
   (= @second second)
  )

  (def ==[other]
   (if (and (== other NOOP) (or (== first NOOP) (== second NOOP))) (return true))
   (unless ($ is_a? other (. class)) return)
   (and (== first ($ first other)) (== second ($ second other)))
  )

  (def to_s[]
   "{{first}} : {{second}}"
  )
 )
)

module Gene
 class Pair
  (attr_reader :first :second)
  def initialize[first second]
   (= @first first)
   (= @second second)
  end

  def ==[other]
   (if (and (== other NOOP) (or (== first NOOP) (== second NOOP))) (return true))
   (unless ($ is_a? other (. class)) return)
   (and (== first ($ first other)) (== second ($ second other)))
  end

  def to_s[]
   "{{first}} : {{second}}"
  end
 end
end

module Gene
  class Pair
    attr_reader :first :second

    def initialize [first second]
      # @first is an instance variable
      = @first  first
      = @second second

    def == other
      if
        and (== other NOOP)
            or (== first NOOP) (== second NOOP)
        return true
      # .is_a? is treated as a method call on an object, @.class is a method call on self
      unless (.is_a? other @.class) return

      and (== first  (.first  other))
          (== second (.second other))

    def to_s [] "{{first}} : {{second}}"

(module Gene
 (class Pair
  (attr_reader :first :second)
  (def initialize[first second]
   (@first  = first)
   (@second = second)
  )

  (def ==[other]
   (if ((other == NOOP) and ((first == NOOP) or (second == NOOP))) (return true))
   (unless (other is_a? @.class)) return)
   ((first == (other .first)) and (second == (other .second)))
  )

  (def to_s[]
   "{{first}} : {{second}}"
  )
 )
)

module Gene
  class Pair
    attr_reader :first :second

    def initialize [first second]
      # @first is instance variable
      #
      # (@first = first): if first item is not a special function,
      # but second is (like =, and, .method, @.method etc), treat it like
      # (= @first first)
      @first  = first
      @second = second

    def == other
      # if ((other == NOOP) and ((first == NOOP) or (second == NOOP))) (return true)
      if
        and (other == NOOP)
            (first == NOOP) or (second == NOOP)
        return true

      # .is_a? is treated as a method call on an object, @.class is a method call on self
      unless (other .is_a? @.class) return

      and (first  == (other .first ))
          (second == (other .second))

    def to_s [] "{{first}} : {{second}}"
    # _ as placeholder
    # def to_s _ "{{first}} : {{second}}"

[1 2 3] = ($ 1 2 3) = ($ 1 $ 2 $ 3)
[] = ($)

(a b c)
a b c
a b
  c

(a (b c))
a (b c)
a
  b c

(a b) != ((a b))

(a b)
a b

((a b))
@
  a b

(a b (c))
a b @ c
a b
  (c)
a b
  @ c

(a [1 2 3] [5 6])
(a [1 2 3] $ 5 $ 6)
a
  $ 1 2 3
  ,
  $ 5 6
a
  $
    1
    2
    3
  $
    5
    6

a
  $ 1
  $ 2
  $ 3
  ,
  $ 4
  $ 5

[(a b) (c d)]
$ (d b) (c d)
$ (a b)
$ (c d)

$
  a b
  c d

{k1 : v1 k2 : v2} = (: k1 v1 k2 v2) = (k1 : v1 k2 : v2)
{} = (:)

(a {k1 : v1 k2 : v2})
(a k1 : v1 k2 : v2)
a
  k1 : v1
  k2 : v2

a k1 : v1
  k2 : v2

(a (b (c d e)))
a (b (c d e))
a
  b (c d e)
a
  b
    c d e
a
  b
    c
      d
      e
a @@ b @@ c d e
a @@ b @@ c d e
a @@ b @@ c
  d
  e

a b c (d e)   = a b c @@ d e
a b (c (d e)) = a b (c @@ d e)
a b (c d) e   = a b c ~ d e

a (b c d) = a @@ b c d = a b ~ c ~ d
(a b c) d = a b c $$ d
a ((b c) d) = a @@ b ~ c d  = a @@ b c @@ d
a (b (c d)) = a @@ b @@ c d = a @@ b c ~ d
a (b c) = a @@ b c = a @@ b ~ c

a b = a ~ b = a @@ b = a $$ b = a :: b
a (b c) = a b ~ c = a @@ b c
(a b) c = a ~ b c = a b $$ c
a (b (c d)) e = a (b c ~ d) e

##############

((a)) = @ @ a

(a b $ c d)  = (a b [c] d)
(a b : c d)  = (a {b : c} d)

(a b ~ c d) = (a (b c) d)

(a b @@ c d) = (a b (c d))
(a b $$ c d) = ((a b) c d)
(a b :: c d) = ((a b) (c d))

(a b @@ c d @@ e f) = (a b (c d (e f)))
(a b $$ c d $$ e f) = (((a b) c d) e f)
(a b :: c d :: e f) = ((a b) (c d) (e f))

@     >     ~    >    : $     >     :: $$ @@

Is it possible to define a set of tags to represent
relationship between items and can represent all linear
data structure without grouping?
E.g.
(a b (c d (e f) g h (i j)) k l (m n) o)
=>
a b @@ c d @@ e f $$ g h @@ i j $$ $$ k l @@ m n $$ o

(a b (c d (e f (g h) i j (k l) m) o (p q (r s) t)) u v)
=>
a b -> c d -> e f -> g h <- i j -> k l <- m <- o -> p q -> r s <- t <- <- u v
a b => c d => e f => g h <= i j => k l <= m <= o => p q => r s <= t <= <= u v

@@ = ->
$$ = <-
:: = ><

@@ $$ :: are not good, just use @~:$
