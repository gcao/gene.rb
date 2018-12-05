#!/usr/bin/env ruby

def dummy n
  if n == 0
    0
  else
    dummy n - 1
  end
end

if ARGV.length != 1
  puts "Usage: #{__FILE__} <number>"
else
  before = Time.now
  puts "#{File.basename(__FILE__)}: #{dummy(ARGV[0].to_i)}"
  puts"Used time: #{Time.now - before}"
end
