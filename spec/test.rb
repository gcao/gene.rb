#!/usr/bin/env ruby

source = %q{
  args           = {}
  args['q']      = 'test'
  args.to_a.collect {|x| "#{x[0]}=#{x[1]}" }.join('&')
}

puts RubyVM::InstructionSequence.new(source).eval

