module EventStore::Persistence::Engines
  class InMemoryEngine < EventStore::Persistence::PersistenceEngine
    def initialize
      @streams_store         = {}
      @undispatched_store    = []
    end
    
    def exists?(stream_id)
      @streams_store.key?(stream_id)
    end
    
    def get_from(stream_id, min_revision: nil)
      stream_store(stream_id)
      .select { |commit| min_revision == nil || commit.stream_revision >= min_revision  }
      .sort do |left, right|
        left.commit_sequence <=> right.commit_sequence
      end
    end
    
    def get_head(stream_id)
      commits = stream_store(stream_id).sort do |left, right|
        left.commit_sequence <=> right.commit_sequence
      end
      commits.length > 0 ?
        ({commit_sequence: commits.last.commit_sequence, stream_revision: commits.last.stream_revision}) : 
        ({commit_sequence: 0, stream_revision: 0})
    end
    
    def for_each_commit(&block)
      all_commits = []
      @streams_store.each_value do |value|
        all_commits.concat value
      end
      all_commits.sort! do |left, right|
        left.commit_timestamp <=> right.commit_timestamp
      end
      all_commits.each(&block)
      nil
    end
    
    def get_undispatched_commits()
      @undispatched_store.clone.sort do |left, right|
        if left.stream_id == right.stream_id
          left.commit_id <=> right.commit_id
        else
          left.stream_id <=> right.stream_id
        end
      end
    end

    def mark_commit_as_dispatched(commit)
      @undispatched_store.delete(commit)
    end

    def commit(transaction_context, attempt)
      @undispatched_store << attempt
      stream_store(attempt.stream_id) << attempt
    end    
    
    def purge
      @streams_store      = {}
      @undispatched_store = []
    end
    
    private
      def stream_store(stream_id)
        @streams_store[stream_id] ||= []
      end
  end
end
