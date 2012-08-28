module EventStore
  autoload :Base, 'event-store/base'
  autoload :Bootstrap, 'event-store/bootstrap'
  autoload :Commit, 'event-store/commit'
  
  module Dispatcher
    autoload :SynchronousDispatcher, 'event-store/dispatcher/synchronous-dispatcher'
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
    autoload :PersistenceFactory, 'event-store/persistence/persistence-factory'
    autoload :PersistenceEngine, 'event-store/persistence/persistence-engine'
  end
  
  module Hooks
    autoload :PipelineHook, 'event-store/hooks/pipeline-hook'
    autoload :DispatcherHook, 'event-store/hooks/dispatcher-hook'
  end
  
  class << self
    def bootstrap(&block)
      Bootstrap.bootstrap(&block)
    end
  end
end