module EventStore::Dispatcher
  class AsynchronousDispatcher < SynchronousDispatcher
    Log = EventStore::Logging::Logger.get 'event-store::dispatcher::asynchronous-dispatcher'
    
    def initialize(*args)
      super
      @queue = Queue.new
      @worker = start_worker @queue
      @ping_mutex = Mutex.new
      @ping_occured = ConditionVariable.new
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
    
    def restart
      raise "Failed to restart. The worker is still running. Status: #{@worker.status}." unless (@worker.status == nil || @worker.status == false)
      @worker = start_worker @queue
    end
    
    def wait_pending
      Log.info 'Waiting for currently pending commits...'
      Log.debug 'Sending :ping command and waiting response...'
      @queue.push(:ping)
      @ping_mutex.synchronize { @ping_occured.wait(@ping_mutex) }
      Log.info 'Pending commits dispatched.'
    end
    
    private def start_worker queue
      Log.info 'Starting asynchronous dispatcher worker thread...'
      worker = Thread.new do
        commit = nil
        loop do
          Log.debug 'Waiting for the next commit from the queue...'
          commit = queue.pop
          break if :stop == commit
          if :ping == commit
            Log.debug ':ping command received. Notifying...'
            @ping_mutex.synchronize { @ping_occured.signal }
            next
          end
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