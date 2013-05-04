puts "Loading #{__FILE__}"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

begin
  require 'gene'

  P = Gene::Parser
  I = Gene::Interpreter
rescue LoadError
  puts "Use bundle exec irb if error is thrown because of gems pulled from github"
end
