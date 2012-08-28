class EventStore::Base
  class InvalidStreamIdError < ::StandardError; end
  
  Log = EventStore::Logging::Logger.get 'event-store'
  
  attr_reader :persistence_engine
    
  def initialize(persistence_engine, dispatcher)
    @persistence_engine, @dispatcher = persistence_engine, dispatcher
    @dispatcher_hook                 = EventStore::Hooks::DispatcherHook.new(dispatcher, persistence_engine)
    @hooks                           = [@dispatcher_hook]
  end
  
  # Obtains all undispatched commits and dispatch them. Mark each commit as dispatched on success.
  # This is usefull at startup stage.
  def dispatch_undispatched
    Log.info "Dispatching undispatched commits..."
    undispatched = @persistence_engine.get_undispatched_commits
    if undispatched.length == 0
      Log.debug "No undispatched commits found."
      return
    end
    Log.debug "#{undispatched.length} found."
    undispatched.each do |commit|
      Log.debug "Dispatching commit '#{commit.commit_id}'..."
      @dispatcher.dispatch(commit)
      Log.debug "Marking commit '#{commit.commit_id}' as dispatched..."
      @persistence_engine.mark_commit_as_dispatched(commit)
    end
    Log.info "All undispatched commits dispatched."
  end
  
  # Opens an event stream
  # If there is at least one commit then the stream get's opened and populated
  # In other case an empty stream returned.
  def open_stream(stream_id)
    raise InvalidStreamIdError.new "stream_id can not be null or empty" if stream_id == nil || stream_id == ""
    EventStore::EventStream.new(stream_id, @persistence_engine, :hooks => @hooks)
  end
  
  #Removes all events from the stream. Use with caution.
  def purge
    @persistence_engine.purge
  end
end
