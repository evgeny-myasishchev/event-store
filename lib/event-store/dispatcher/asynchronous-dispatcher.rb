module EventStore::Dispatcher
  class AsynchronousDispatcher < SynchronousDispatcher
    Log = EventStore::Logging::Logger.get 'event-store::dispatcher::asynchronous-dispatcher'
    
    def initialize(*args)
      super
      @queue = Queue.new
      @worker = start_worker @queue
    end
    
    alias_method :super_schedule_dispatch, :schedule_dispatch
    def schedule_dispatch(commit)
      @queue.push(commit)
    end
    
    # Sends a stop command and waits for all pending commits to be dispatched.
    def stop
      Log.info 'Stopping the asynchronous dispatcher...'
      @queue.push(:stop)
      @worker.join
      Log.info 'Stopped.'
    end
    
    private def start_worker queue
      Log.info 'Starting asynchronous dispatcher worker thread...'
      Thread.new do
        until (commit = queue.pop) == :stop
          super_schedule_dispatch commit
        end
      end
    end
  end
end