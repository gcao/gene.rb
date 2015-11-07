require 'logem'

require 'gene/types'
require 'gene/stream'
require 'gene/context'
require 'gene/handlers'

require 'gene/parse_error'
require 'gene/parser'

require 'gene/interpreter'

require 'gene/file_system'

module Gene
  NOOP       = Gene::Types::Group.new()
  ARRAY      = Gene::Types::Ident.new('[]')
  HASH       = Gene::Types::Ident.new('{}')
  RANGE      = Gene::Types::Ident.new('..')
  #EXPLODE_OP = Gene::Types::Ident.new('\\')  # (a (\\ b)) = (a b)
end
