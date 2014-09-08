module EventStore::Dispatcher
  class Base
    # Installs dispatch pipeline hooks
    # * after_dispatch - invoked after successful dispatch
    def hook_into_pipeline(after_dispatch: nil)
    
    end
    
    def schedule_dispatch(commit)
      raise "Not implemented"
    end
    
    def dispatch_immediately(commit)
      raise 'Abstract method.'
    end
  end
end