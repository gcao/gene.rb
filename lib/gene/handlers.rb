module Gene
  NOT_HANDLED = Object.new

  module Handlers
  end
end

require 'gene/handlers/array_handler'
require 'gene/handlers/hash_handler'
require 'gene/handlers/range_handler'
require 'gene/handlers/complex_string_handler'
require 'gene/handlers/base64_handler'
require 'gene/handlers/group_handler'
require 'gene/handlers/metadata_handler'
require 'gene/handlers/reference_handler'
require 'gene/handlers/regexp_handler'

