#!/usr/bin/env ruby

def ragel_to_ruby
	ragel_file = File.dirname(__FILE__) + "/ami.rl"
  puts `ragel -n -R #{ragel_file} | rlgen-ruby -o #{ragel_file[0..-2] + 'b'}`
end

ragel_to_ruby if $0 == __FILE__