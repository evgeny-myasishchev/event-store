module EventStore::Persistence::Engines
  class InMemoryEngine < EventStore::Persistence::PersistenceEngine
    def initialize
      @streams_store = {}
      @checkpoint_sequence = 0
    end
    
    def exists?(stream_id)
      @streams_store.key?(stream_id)
    end
    
    def get_from(stream_id, min_revision: nil)
      stream_store(stream_id)
        .select { |commit| min_revision == nil || commit.stream_revision >= min_revision  }
        .sort_by { |c| c.checkpoint }
    end
    
    def get_head(stream_id)
      commits = stream_store(stream_id).sort do |left, right|
        left.commit_sequence <=> right.commit_sequence
      end
      commits.length > 0 ?
        ({commit_sequence: commits.last.commit_sequence, stream_revision: commits.last.stream_revision}) : 
        ({commit_sequence: 0, stream_revision: 0})
    end
    
    def for_each_commit(checkpoint: nil, &block)
      @streams_store.lazy
        .flat_map {|k, v| v }
        .select {|c| checkpoint.nil? || c.checkpoint > checkpoint }
        .to_a.sort_by! { |c| c.checkpoint }
        .each(&block)
    end

    def commit(attempt)
      commit = EventStore::Commit.new attempt.hash.merge checkpoint: @checkpoint_sequence += 1
      stream_store(attempt.stream_id) << commit
      commit
    end
    
    def purge
      @streams_store = {}
    end
    
    private
      def stream_store(stream_id)
        @streams_store[stream_id] ||= []
      end
  end
end
