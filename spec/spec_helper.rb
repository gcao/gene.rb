$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rspec/autorun'
require 'v8'
require 'gene'

#ENV['LOGEM_LOG_LEVEL'] ||= 'trace'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end

# Remove leading/trailing spaces, new-lines
def compress code
  code.gsub(/(^\s*)|(\s*\n\s*)|(\s*$)/, '')
end

def compare_code first, second
  compress(first.to_s).should == compress(second.to_s)
end

def print_code code
  puts
  puts code.to_s.gsub(/^\s*/, '')
end

Root = Gene::Lang::Compiler::Root
Variable = Gene::Lang::Compiler::Variable