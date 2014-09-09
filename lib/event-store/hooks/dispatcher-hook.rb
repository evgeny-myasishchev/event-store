module EventStore::Hooks
  class DispatcherHook < PipelineHook
    Log = EventStore::Logging::Logger.get 'event-store::dispatcher-hook'
    
    attr_reader :dispatcher, :persistence_engine
    
    def initialize(dispatcher, persistence_engine)
      @dispatcher, @persistence_engine = dispatcher, persistence_engine
      @dispatcher.hook_into_pipeline after_dispatch: ->(commit) {
        Log.debug "Marking commit '#{commit.commit_id}' as dispatched..."
        persistence_engine.mark_commit_as_dispatched(commit)
      }
    end
    
    #Dispatch the commit and mark it as dispatched on success
    def post_commit(commit)
      Log.debug "Dispatching commit '#{commit.commit_id}'..."
      dispatcher.schedule_dispatch(commit)
    end
  end
end