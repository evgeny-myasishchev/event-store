module Xtms
  module EventStore
    autoload :Base, 'xtms-event-store/base'
    autoload :Bootstrap, 'xtms-event-store/bootstrap'
    autoload :Commit, 'xtms-event-store/commit'
    
    module Dispatcher
      autoload :SynchronousDispatcher, 'xtms-event-store/dispatcher/synchronous-dispatcher'
    end
    
    autoload :EventMessage, 'xtms-event-store/event-message'
    autoload :EventStream, 'xtms-event-store/event-stream'
    autoload :Identity, 'xtms-event-store/identity'
    
    module Infrastructure
      autoload :ReadOnlyArray, 'xtms-event-store/infrastructure/read-only-array'
    end
    
    module Logging
      autoload :Logger, 'xtms-event-store/logging/logger'
      autoload :Factory, 'xtms-event-store/logging/factory'
      autoload :Log4rFactory, 'xtms-event-store/logging/log4r-factory'
    end
    
    module Persistence
      module Engines
        autoload :InMemoryEngine, 'xtms-event-store/persistence/engines/in-memory-engine'
        autoload :SqlEngine, 'xtms-event-store/persistence/engines/sql-engine'
      end
      autoload :PersistenceFactory, 'xtms-event-store/persistence/persistence-factory'
      autoload :PersistenceEngine, 'xtms-event-store/persistence/persistence-engine'
    end
    
    module Hooks
      autoload :PipelineHook, 'xtms-event-store/hooks/pipeline-hook'
      autoload :DispatcherHook, 'xtms-event-store/hooks/dispatcher-hook'
    end
  end
end
