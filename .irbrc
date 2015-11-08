puts "Loading #{__FILE__}"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

begin
  require 'gene'

  P = Parser           = Gene::Parser
  T = TypesInterpreter = Gene::TypesInterpreter
  R = RubyInterpreter  = Gene::RubyInterpreter
  F = FileSystem       = Gene::FileSystem
rescue LoadError
  puts "Use bundle exec irb if error is thrown because of gems pulled from github"
end
