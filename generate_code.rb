#!/usr/bin/env ruby

def ragel_to_ruby
  ragel_file = File.dirname(__FILE__) + "/ami.rl"
  ruby_output = ragel_file[0..-2] + 'b'
  puts `ragel -n -R #{ragel_file} | rlgen-ruby -o #{ruby_output}`
  
  comment = '# THIS FILE WAS AUTOMATICALLY GENERATED BY RAGEL. DO NOT MODIFY!'
  code = File.read(ruby_output).split "\n"
  File.open ruby_output, "w" do |file|
    until code.empty?
      file.puts code.shift
      file.puts comment
    end
  end
end

ragel_to_ruby if $0 == __FILE__
