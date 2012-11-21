module EventStore::Hooks
  class DeferredDispatcherHook < PipelineHook
    Log = EventStore::Logging::Logger.get 'event-store::deferred-dispatcher-hook'
    
    def initialize(dispatcher_hook)
      @dispatcher_hook = dispatcher_hook
      @post_commit = []
    end
    
    def post_commit(commit)
      @post_commit << commit
    end
    
    def dispatch_deferred
      Log.debug "Dispatching deferred commits..."
      @post_commit.each { |commit| @dispatcher_hook.post_commit(commit)  }
      @post_commit.clear
    end
  end
end