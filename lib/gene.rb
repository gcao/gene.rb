require 'logem'

require 'gene/entity'
require 'gene/group'

require 'gene/handler'

require 'gene/parse_error'
require 'gene/parser'

require 'gene/interpreter'

module Gene
  NOOP       = Entity.new('')
  ARRAY      = Entity.new('[]')
  HASH       = Entity.new('{}')
  EXPLODE_OP = Entity.new('\\')  # (a (\\ b)) = (a b)
end
