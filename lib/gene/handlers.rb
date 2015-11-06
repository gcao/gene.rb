module Gene
  NOT_HANDLED = Object.new
  
  module Handlers
  end
end

require 'gene/handlers/base'
require 'gene/handlers/array_handler'
require 'gene/handlers/hash_handler'
require 'gene/handlers/class_handler'
require 'gene/handlers/method_handler'
require 'gene/handlers/range_handler'
