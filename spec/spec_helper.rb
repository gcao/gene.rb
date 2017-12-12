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

#################### HELPER METHODS ####################

# Remove leading/trailing spaces, new-lines
def compress code
  code.gsub(/(^\s*)|(\s*\n\s*)|(\s*$)/, '')
end

def compare_code first, second
  compress(first.to_s).should == compress(second.to_s)
end

def beautify code
  File.write '/tmp/generated.js', code.to_s
  `jsbeautifier /tmp/generated.js 2>&1 > /tmp/generated1.js`
  File.read('/tmp/generated1.js')
end

def print_code code
  puts
  puts beautify code
end