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
 (block
  (class Pair
   (block
    (attr_reader :first :second)
    (def initialize[first second]
     (block
      (@first  = first)
      (@second = second)
     )
    )

    (def ==[other]
     (block
      (if ((other == noop) and ((first == noop) or (second == noop))) (return true))
      (unless (other is_a? @.class)) return)
      ((first == (other .first)) and (second == (other .second)))
     )
    )

    (def to_s[]
     (block
      "{{first}} : {{second}}"
     )
    )
   )
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
            or (first == NOOP) (second == NOOP)
        return true

      # .is_a? is treated as a method call on an object, @.class is a method call on self
      unless (other .is_a? @.class) return

      and (first  == (other .first ))
          (second == (other .second))

    def to_s [] "{{first}} : {{second}}"
    # _ as placeholder
    # def to_s _ "{{first}} : {{second}}"

[1 2 3] = ($ 1 2 3)
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
a
  $ 1 2 3
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
    2
    3
  $ 5
    6

[(a b) (c d)]
$ (a b) (c d)
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

a
  : k1 v1 k2 v2

a
  : k1 v1
    k2 v2

(a {k1 : v1} {k2 : v2})

a
  : k1 v1
  : k2 v2

a b c d
is the same as
a b \
  c d

a b
\ c d

a b
  \ c d

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
(a b || c d) = (a b c d)

(a b @@ c d @@ e f) = (a b (c d (e f)))
(a b $$ c d $$ e f) = (((a b) c d) e f)
(a b :: c d :: e f) = ((a b) (c d) (e f))

@     >     ~    >    : $     >     :: $$ @@ ||

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

a
0 a

(a)
1 a

(a b)
1 a 1 b
1 a b

((a b) c)
2 a 2 b 1 c
2 a b 1 c

((a (b c)) d)
2 a 3 b 3 c 1 d
2 a 3 b c 1 d

((a (b (c d))) e)
2 a 3 b 4 c 4 d 1 e
2 a 3 b 4 c d 1 e

((a (b (c (d e)))) f)
2 a 3 b 4 c 5 d 5 e 1 f
2 a 3 b 4 c 5 d e 1 f

((a (b (c (d (e f))))) g)
2 a 3 b 4 c 5 d 6 e 6 f 1 g
2 a 3 b 4 c 5 d 6 e f 1 g

(a b (c (d (e f)) g h (i j)) k l (m n) o)
1 a b 2 c 3 d 4 e f 2 g h 3 i j 1 k l 2 m n 1 o

