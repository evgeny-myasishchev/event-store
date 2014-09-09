module EventStore::Dispatcher
  class Base
    def initialize
      @hooks = {
        after_dispatch: []
      }
    end
    
    # Installs dispatch pipeline hooks
    # * after_dispatch - invoked after successful dispatch
    def hook_into_pipeline(after_dispatch: nil)
      @hooks[:after_dispatch] << after_dispatch if after_dispatch
    end
    
    def schedule_dispatch(commit)
      dispatch_immediately commit
      @hooks[:after_dispatch].each { |hook| hook.call(commit) }
    end
    
    def dispatch_immediately(commit)
      raise 'Abstract method.'
    end
  end
end