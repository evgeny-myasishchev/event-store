module Xtms::EventStore::Hooks
  class DispatcherHook < PipelineHook
    Log = Xtms::EventStore::Logging::Logger.get 'xtms-event-store::dispatcher-hook'
    
    attr_reader :dispatcher, :persistence_engine
    
    def initialize(dispatcher, persistence_engine)
      @dispatcher, @persistence_engine = dispatcher, persistence_engine
    end
    
    #Dispatch the commit and mark it as dispatched on success
    def post_commit(commit)
      Log.debug "Dispatching commit '#{commit.commit_id}'..."
      dispatcher.dispatch(commit)
      Log.debug "Marking commit '#{commit.commit_id}' as dispatched..."
      persistence_engine.mark_commit_as_dispatched(commit)
    end
  end
end