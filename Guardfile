# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
end

# It's too slow to run all tests so using the shell guard below instead
# guard 'rspec' do
#   watch(%r{^(lib|spec)/.+\.(rb|treetop|gene)$})
# end

guard :shell do
  watch(%r{^(lib|spec)/.+\.(rb|treetop|gene)$}) {|m|
    `rspec spec/gene/lang/jit_* spec/gene/parser_spec.rb`
    # `rspec spec/gene/lang/jit_spec.rb:15`
  }
end
