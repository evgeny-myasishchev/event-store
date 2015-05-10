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
end