require 'logem'

require 'gene/types'
require 'gene/stream'
require 'gene/handlers'

require 'gene/parse_error'
require 'gene/parser'

require 'gene/abstract_interpreter'
require 'gene/core_interpreter'
require 'gene/ruby_interpreter'
require 'gene/javascript_interpreter'

require 'gene/file_system'

module Gene
  NOOP       = Gene::Types::Noop.new()
  #EXPLODE_OP = Gene::Types::Ident.new('\\')  # (a (\\ b)) = (a b)
end
