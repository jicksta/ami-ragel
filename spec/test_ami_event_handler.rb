require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), *%w[.. event_handler.rb])

context "Registration of events" do
  
  include EventHandlerTestHelper
  
  after:each do
    EventHandler.clear!
  end
  
  specify "registered_patterns() should contain all patterns when a subclass executes on() " do
    
    pattern_one = "one"
    subclass_and_register_pattern pattern_one
    
    pattern_two = "two"
    subclass_and_register_pattern pattern_two
    
    EventHandler.registered_patterns.size.should.equal 2
    EventHandler.registered_patterns.has_key?("one").should.equal true
    EventHandler.registered_patterns.has_key?("two").should.equal true
    
  end
  
  it "should raise an error if no block is given" do
    the_following_code {
      subclass_and_register_pattern_with_block("does_not_matter")
    }.should.raise
  end
  
   it "should clear all registered patterns with clear!()" do
    subclass_and_register_pattern "pattern_doesnt_matter"
    EventHandler.registered_patterns.size.should.equal 1
    EventHandler.clear!
    EventHandler.registered_patterns.should.be.empty
   end
     
   it "should have no registered patterns by default" do
     EventHandler.registered_patterns.should.be.empty
   end
   
end

context "EventHandlerTestHelper" do
  
  include EventHandlerTestHelper
  
  specify "#subclass_and_register_pattern should throw the symbol given as the second argument" do
    the_following_code {
      event_name = "ping"
      subclass_and_register_pattern(event_name, :throw_me_plz).handle_event(event_with_name(event_name))
    }.should.throw :throw_me_plz
  end
  
  it "should not throw a symbol normally" do
    the_following_code do
      event_name = "login"
      subclass_and_register_pattern(event_name).handle_event(event_with_name(event_name))
    end.should.not.throw
  end
  
  specify "#subclass_and_register_pattern_with_block should run the block given" do
    the_following_code {
      event_name = "sippeers"
      subclass_and_register_pattern_with_block(event_name) do
        throw :got_here
      end.handle_event(event_with_name(event_name))
    }.should.throw :got_here
  end
  
end

BEGIN {
module EventHandlerTestHelper
  def subclass_and_register_pattern(pattern, thrown_symbol=nil, &block)
    subclass_and_register_pattern_with_block pattern do
      throw thrown_symbol if thrown_symbol
    end
  end
  
  def subclass_and_register_pattern_with_block(pattern, &block)
    returning(Class.new(EventHandler)) do |klass|
      klass.class_eval do
        on(pattern, &block)
      end
    end
  end
  
  
  def event_with_name(name)
    { :name => name }
  end
end
}