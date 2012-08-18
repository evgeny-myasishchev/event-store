module Xtms::EventStore::Dispatcher
  class SynchronousDispatcher
    def initialize(&receiver)
      @receiver = receiver
    end
    
    #dispatch the specified commit to some kind of communications infrastructure.
    def dispatch(commit)
      @receiver.call(commit)
    end
  end
end
    