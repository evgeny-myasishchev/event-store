module EventStore::Persistence
  module Engines
    autoload :InMemoryEngine, 'event-store/persistence/engines/in-memory-engine'
    autoload :SqlEngine, 'event-store/persistence/engines/sql-engine'
  end
  
  autoload :PersistenceEngine, 'event-store/persistence/persistence-engine'
  autoload :PersistenceFactory, 'event-store/persistence/persistence-factory'
  autoload :Serializers, 'event-store/persistence/serializers'
end