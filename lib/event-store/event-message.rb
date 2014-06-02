class EventStore::EventMessage
  
  JsonClassKey = 'json_class'.freeze
  BodyKey = 'body'.freeze
  HeadersKey = 'headers'.freeze
  
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
  
  def to_json(*args)
    {JsonClassKey => self.class, BodyKey => @body, HeadersKey => headers}.to_json
  end
  
  def self.json_create(data)
    new(data[BodyKey], data[HeadersKey])
  end
end
