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
      Log.debug "Adding new commit '#{commit.commit_id}' to queue. Worker #{@worker} status: #{@worker.status}"
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
      worker = Thread.new do
        commit = nil
        loop do
          Log.debug 'Waiting for the next commit from the queue...'
          commit = queue.pop
          break if :stop == commit
          
          Log.debug "Worker got new commit from the queue '#{commit.commit_id}'."
          begin
            super_schedule_dispatch commit
          rescue Exception => e
            Log.error "Failed to dispatch commit: #{commit}.\n#{e}"
          end
        end
        Log.debug 'Worker stopped.'
      end
      worker
    end
  end
end