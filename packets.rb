class NormalAmiResponse
  
  def initialize
    @pairs = {}
  end
  
  def [](arg)
    @pairs[arg]
  end
  
  def []=(key,value)
    puts "Setting '#{key}' to '#{value}'!"
    @pairs[key] = value
  end
  
end

class Event < NormalAmiResponse
  def initialize(name)
    super()
    @name = name.underscore.to_sym
  end
end
