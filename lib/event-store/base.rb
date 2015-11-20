class EventStore::Base
  Log = EventStore::Logging::Logger.get 'event-store'
  
  attr_reader :persistence_engine, :dispatcher, :dispatcher_hook
    
  def initialize(persistence_engine, dispatcher)
    @persistence_engine, @dispatcher = persistence_engine, dispatcher
    @dispatcher_hook                 = EventStore::Hooks::DispatcherHook.new(dispatcher, persistence_engine)
    @hooks                           = [@dispatcher_hook]
  end
  
  # Obtains all undispatched commits and dispatch them. Mark each commit as dispatched on success.
  # This is usefull at startup stage.
  def dispatch_undispatched
    Log.info 'Dispatching undispatched commits...'
    undispatched = @persistence_engine.get_undispatched_commits
    if undispatched.length == 0
      Log.info 'No undispatched commits found.'
      return
    end
    Log.debug "#{undispatched.length} found."
    undispatched.each do |commit|
      Log.debug "Dispatching commit '#{commit.commit_id}'..."
      @dispatcher.schedule_dispatch(commit)
    end
    Log.info 'All undispatched commits dispatched.'
  end
  
  # Returns true if the stream exists.
  def stream_exists?(stream_id)
    @persistence_engine.exists?(stream_id)
  end
  
  # Creates new event stream
  def create_stream(stream_id)
    EventStore::EventStream.create_stream(stream_id, @persistence_engine, :hooks => @hooks)
  end
  
  # Opens a new stream optionally populating starting from min_revision
  def open_stream(stream_id, min_revision: nil)
    EventStore::EventStream.open_stream(stream_id, @persistence_engine, :hooks => @hooks, min_revision: min_revision)
  end
  
  def transaction(&block)
    persistence_engine.transaction &block
  end
  
  #Removes all events from the stream. Use with caution.
  def purge
    @persistence_engine.purge
  end
end
