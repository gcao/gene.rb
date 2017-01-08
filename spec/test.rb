#!/usr/bin/env ruby

module FakeModule
  def self.included target
    puts 'FakeModule module'
    # Logic goes here
  end
end

def FakeModule(*args)
  Module.new do
    define_singleton_method :included do |target|
      puts "FakeModule(#{args.inspect[1..-2]})"
      # Logic goes here
    end
  end
end

module Lib
  module FakeModule2
    def self.included target
      puts 'FakeModule2 module'
      # Logic goes here
    end
  end

  def self.FakeModule2(*args)
    Module.new do
      define_singleton_method :included do |target|
        puts "FakeModule2(#{args.inspect[1..-2]})"
        # Logic goes here
      end
    end
  end
end

class A
  include FakeModule
  include FakeModule('test')
  include Lib::FakeModule2
  include Lib::FakeModule2('test')
end

#source = %q{
#  args           = {}
#  args['q']      = 'test'
#  args.to_a.collect {|x| "#{x[0]}=#{x[1]}" }.join('&')
#}

#puts RubyVM::InstructionSequence.new(source).eval

