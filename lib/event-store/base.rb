class EventStore::Base
  Log = EventStore::Logging::Logger.get 'event-store'

  extend Forwardable
  
  attr_reader :persistence_engine

  delegate :for_each_commit => :persistence_engine
    
  def initialize(persistence_engine)
    @persistence_engine = persistence_engine
  end
  
  # Returns true if the stream exists.
  def stream_exists?(stream_id)
    @persistence_engine.exists?(stream_id)
  end
  
  # Creates new event stream
  def create_stream(stream_id)
    EventStore::EventStream.create_stream(stream_id, @persistence_engine)
  end
  
  # Opens a new stream optionally populating starting from min_revision
  def open_stream(stream_id, min_revision: nil)
    EventStore::EventStream.open_stream(stream_id, @persistence_engine, min_revision: min_revision)
  end
  
  def transaction(&block)
    persistence_engine.transaction &block
  end
  
  #Removes all events from the stream. Use with caution.
  def purge
    @persistence_engine.purge
  end
end
