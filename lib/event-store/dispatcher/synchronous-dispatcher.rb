module EventStore::Dispatcher
  class SynchronousDispatcher < Base
    attr_reader :receiver
    def initialize(&receiver)
      @receiver = receiver
      super
    end
    
    #dispatch the specified commit to some kind of communications infrastructure.
    def dispatch_immediately(commit)
      @receiver.call(commit)
    end
  end
end
    