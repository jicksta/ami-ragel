require File.join(File.dirname(__FILE__), "ami.rb")

class EventHandler
  
  @@patterns = {}
  
  class << self
    
    def clear!
      @@patterns.clear
    end
    
    def registered_patterns
      @@patterns.clone
    end
    
    def handle_event(event)
      @@patterns.each_pair do |pattern, block|
        if pattern.kind_of? String
          block.call if pattern == event[:name]
        elsif pattern.kind_of? Hash
          raise NotImplementedError
        end
      end
    end
    
    protected

    def on(pattern, &block)
      raise unless block_given?
      @@patterns[pattern] = block
    end
    
  end
end

class MyHandler < EventHandler
  
end
