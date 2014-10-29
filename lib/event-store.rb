module EventStore
  class ConcurrencyError < StandardError 
  end

  autoload :Base, 'event-store/base'
  autoload :Bootstrap, 'event-store/bootstrap'
  autoload :Commit, 'event-store/commit'
  
  module Dispatcher
    autoload :Base, 'event-store/dispatcher/base'
    autoload :SynchronousDispatcher, 'event-store/dispatcher/synchronous-dispatcher'
    autoload :AsynchronousDispatcher, 'event-store/dispatcher/asynchronous-dispatcher'
  end
  
  autoload :EventMessage, 'event-store/event-message'
  autoload :EventStream, 'event-store/event-stream'
  autoload :Identity, 'event-store/identity'
  
  module Infrastructure
    autoload :ReadOnlyArray, 'event-store/infrastructure/read-only-array'
  end
  
  module Logging
    autoload :Logger, 'event-store/logging/logger'
    autoload :Factory, 'event-store/logging/factory'
    autoload :Log4rFactory, 'event-store/logging/log4r-factory'
  end
  
  module Persistence
    module Engines
      autoload :InMemoryEngine, 'event-store/persistence/engines/in-memory-engine'
      autoload :SqlEngine, 'event-store/persistence/engines/sql-engine'
    end
    autoload :PersistenceEngine, 'event-store/persistence/persistence-engine'
    autoload :PersistenceFactory, 'event-store/persistence/persistence-factory'
    autoload :Serializers, 'event-store/persistence/serializers'
  end
  
  module Hooks
    autoload :DeferredDispatcherHook, 'event-store/hooks/deferred-dispatcher-hook'
    autoload :DispatcherHook, 'event-store/hooks/dispatcher-hook'
    autoload :PipelineHook, 'event-store/hooks/pipeline-hook'
  end
  
  class << self
    def bootstrap(&block)
      Bootstrap.bootstrap(&block)
    end
  end
end