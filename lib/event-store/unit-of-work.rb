# Unit of Work and there is not mutch to add here :)
class EventStore::UnitOfWork
  def initialize(event_store, dispatcher_hook)
    @event_store = event_store
    @deferred_dispatcher_hook = EventStore::Hooks::DeferredDispatcherHook.new(dispatcher_hook)
    @hooks = [@deferred_dispatcher_hook]
    @opened_streams = {}
  end
  
  # Opens the stream and tracks all the modifications of it
  # All the modification of the stream are saved on commit_changes
  def open_stream(stream_id)
    return @opened_streams[stream_id] if @opened_streams.key?(stream_id)
    @opened_streams[stream_id] = EventStore::EventStream.
      new(stream_id, @event_store.persistence_engine, :hooks => @hooks)
  end
  
  # Commits the changes from all opened streams and saves them to the store
  # Commits are dispatched only after all the events from all opened streams are saved to the store
  def commit_changes(headers = {})
    @opened_streams.values.each { |stream| stream.commit_changes(headers) }
    @deferred_dispatcher_hook.dispatch_deferred
  end
end