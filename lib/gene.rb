#require 'logem'

require 'gene/entity'
require 'gene/group'

require 'gene/parse_error'
require 'gene/parser'
require 'gene/interpreter'

module Gene
  NOOP       = Entity.new('')
  # (a (\\ b)) = (a b)
  EXPLODE_OP = Entity.new('\\')
end
