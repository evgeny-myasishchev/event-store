class EventStore::EventMessage
  
  #Gets or sets the actual event message body.
  attr_reader :body
  
  #The metadata which provides additional, unstructured information about this message.
  attr_reader :headers
  
  def initialize(body, headers = {})
    @body    = body
    @headers = headers
  end
  
  def ==(other)
    @body == other.body && @headers == other.headers
  end
  
  def eql?(other)
    self == other
  end
end
