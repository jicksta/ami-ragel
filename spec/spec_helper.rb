require 'rubygems'
require 'active_support'
require 'test/spec'
require 'stringio'
require File.dirname(__FILE__) + "/../generate_code"

# Regenerate the Ruby source code
ragel_to_ruby

alias the_following_code lambda

class Object
  def metaclass
    class << self; self; end
  end
  
  def meta_eval(&block)
    metaclass.instance_eval(&block)
  end
  
  def meta_def(name, &block)
    meta_eval { define_method(name, &block) }
  end
end