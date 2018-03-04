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

def compare_code expected, actual
  result = (beautify(expected) == beautify(actual))
  if not result
    puts
    puts "vvvvvvvvvvvvvvv Expected vvvvvvvvvvvvvvv"
    puts
    puts beautify(expected).gsub(/^/m, '      ')
    puts
    puts "----------------------------------------"
    puts
    puts beautify(actual).gsub(/^/m, '      ')
    puts
    puts "^^^^^^^^^^^^^^^  Actual  ^^^^^^^^^^^^^^^"
  end
  beautify(actual).should == beautify(expected)
end

# npm install -g js-beautify
# https://www.npmjs.com/package/js-beautify
# npm install -g cli-highlight
# https://www.npmjs.com/package/cli-highlight
def beautify code
  `echo '#{code.to_s.strip}' | js-beautify -s 2`
  # File.write '/tmp/generated.js', code.to_s
  # `js-beautify /tmp/generated.js 2>&1 > /tmp/generated1.js`
  # File.read('/tmp/generated1.js')
end