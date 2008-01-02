require 'rubygems'
require 'active_support'
require 'test/spec'
require 'stringio'
require File.join(File.dirname(__FILE__), *%w[.. generate_code])

# Regenerate the Ruby source code
ragel_to_ruby

alias the_following_code lambda


