class EventStore::EventMessage
  
  JsonClassKey = 'json_class'.freeze
  BodyKey = 'body'.freeze
  
  #Gets or sets the actual event message body.
  attr_reader :body
  
  def initialize(body)
    @body    = body
  end
  
  def ==(other)
    return false unless other.is_a?(self.class)
    @body == other.body
  end
  
  def eql?(other)
    self == other
  end
  
  def to_json(*args)
    {JsonClassKey => self.class, BodyKey => @body}.to_json
  end
  
  def self.json_create(data)
    new(data[BodyKey])
  end
end
