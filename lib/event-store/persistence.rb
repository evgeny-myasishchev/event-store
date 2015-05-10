module EventStore::Persistence
  class TransactionContext
    attr_reader :after_commit_hooks
    def initialize
      @after_commit_hooks = []
    end
    
    def after_commit &hook
      @after_commit_hooks << hook
    end
  end
  
  class NoTransactionContext < TransactionContext
  end
  
  module Engines
    autoload :InMemoryEngine, 'event-store/persistence/engines/in-memory-engine'
    autoload :SqlEngine, 'event-store/persistence/engines/sql-engine'
  end
  
  autoload :PersistenceEngine, 'event-store/persistence/persistence-engine'
  autoload :PersistenceFactory, 'event-store/persistence/persistence-factory'
  autoload :Serializers, 'event-store/persistence/serializers'
  autoload :TransactionContext, 'event-store/persistence/transaction-context'
end