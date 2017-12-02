puts "Loading #{__FILE__}"

require 'v8'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

begin
  require 'gene'
rescue LoadError
  puts "Use bundle exec irb if error is thrown because of gems pulled from github"
end

P = Parser           = Gene::Parser
# C = CoreInterpreter  = Gene::CoreInterpreter
# R = RubyInterpreter  = Gene::RubyInterpreter
# J = JavascriptInterpreter = Gene::JavascriptInterpreter
# F = FileSystem       = Gene::FileSystem
C = Compiler         = Gene::Lang::Compiler

@ctx = V8::Context.new
@ctx.eval File.read 'gene-js/build/src/index.js'
