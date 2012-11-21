module EventStore::Hooks
  class DeferredDispatcherHook < PipelineHook
    def initialize(dispatcher_hook)
      @dispatcher_hook = dispatcher_hook
    end
    
    def post_commit(commit)
      raise "Not implemented"
    end
    
    def dispatch_deferred
      raise "Not implemented"
    end
  end
end