module EventStore::Dispatcher
  class SynchronousDispatcher < Base
    attr_reader :receiver
    def initialize(&receiver)
      @receiver = receiver
    end
    
    #dispatch the specified commit to some kind of communications infrastructure.
    def dispatch(commit)
      @receiver.call(commit)
    end
  end
end
    