module EventStore::Persistence
  
  #Abstract class that defines methods that are required to persist commits
  class PersistenceEngine
    
    # Abstract transaction context if supported by the persistence engine
    class TransactionContext
    end
    
    class NoTransactionContext
    end
    
    # Returns true if transactions are supported by the engine
    def supports_transactions?
      false
    end
    
    # Starts database transaction. Given block will be called with transaction context
    def transaction(&block)
      yield NoTransactionContext.new
    end
    
    # Returns true if the stream exists. Returns false otherwise.
    def exists?(stream_id)
      raise 'Not implemented'
    end
    
    #Gets the corresponding commits from the stream indicated with the identifier.
    #Returned commits are sorted in ascending order from older to newer.
    #If no commits are found then empty array returned.
    #Optionally retrieved commits can be optionally retrieved from min_revision (inclusive)
    def get_from(stream_id, min_revision: nil)
      raise "Not implemented"
    end
    
    # Get head information for the given stream.
    # The result is a hash with following attributes:
    # * :stream_revision
    # * :commit_sequence
    # The attributes above correspond to the most recent commit.
    def get_head(stream_id)
      raise 'Not implemented'
    end
    
    #Iterates through all commits from all streams
    #Retrieved commits are sorted in ascending order from older to newer.
    def for_each_commit(&block)
      raise "Not implemented"
    end

    #Gets a set of commits that has not yet been dispatched.
    # => The set of commits to be dispatched.
    def get_undispatched_commits()
      raise "Not implemented"
    end

    #Marks the commit specified as dispatched.
    # * commit - The commit to be marked as dispatched.
    def mark_commit_as_dispatched(commit)
      raise "Not implemented"
    end

    #Writes the to-be-commited events provided to the underlying persistence mechanism.
    # * attempt - the series of events and associated metadata to be commited.
    def commit(attempt)
      raise "Not implemented"
    end    

    #Initialize engine if needed
    def init_engine
    end

    #Remove all events from the stream
    def purge
      raise "Not implemented"
    end
  end
end