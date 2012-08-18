require 'sequel'

module EventStore::Persistence::Engines
  class SqlEngine < EventStore::Persistence::PersistenceEngine
    class EngineNotInitialized < ::StandardError
      def initialize
        super("The engine has not been initialized. Please make sure the engine is initialized prior to using it. Initialization can be done with 'init_engine' method")
      end
    end
    
    Log = EventStore::Logging::Logger.get("xtms-event-store::persistence::sql-engine")
    
    attr_reader :connection
    
    # 
    # connection_specification - Connection specification for Sequel
    # See here: http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html
    # 
    def initialize(connection_specification = {}, options = {})
      connection_specification = connection_specification.dup
      @options = {
        :table => :'event-store-commits',
        :orm_log_level => :debug
      }.merge! options
      
      @connection = Sequel.connect connection_specification
      @connection.loggers << EventStore::Logging::Logger.get("xtms-event-store::persistance::orm")
      @connection.sql_log_level = @options[:orm_log_level]
      
      @initialized = false
    end
    
  	#Gets the corresponding commits from the stream indicated with the identifier.
  	#Returned commits are sorted in ascending order from older to newer.
  	#If no commits are found then empty array returned.
    def get_from(stream_id)
      ensure_initialized!
      map_to_commits @connection.call(:select_from_stream, stream_id: stream_id)
    end
    
    def for_each_commit(&block)
      ensure_initialized!
      @storage.order(:commit_timestamp).each do |c|
        yield map_commit(c)
      end
      nil
    end

    #Gets a set of commits that has not yet been dispatched.
    # => The set of commits to be dispatched.
    def get_undispatched_commits()
      ensure_initialized!
      map_to_commits @connection.call(:select_undispatched)
    end

    #Marks the commit specified as dispatched.
    # * commit - The commit to be marked as dispatched.
    def mark_commit_as_dispatched(commit)
      ensure_initialized!
      @connection.call(:mark_as_dispatched, commit_id: commit.commit_id)
      nil
    end

    #Writes the to-be-commited events provided to the underlying persistence mechanism.
    # * attempt - the series of events and associated metadata to be commited.
    def commit(attempt)
      ensure_initialized!
      Log.debug("Committing attempt #{attempt}")
      @connection.call(:insert_new_commit, {
        stream_id: attempt.stream_id,
        commit_id: attempt.commit_id,
        commit_sequence: attempt.commit_sequence,
        stream_revision: attempt.stream_revision,
        commit_timestamp: attempt.commit_timestamp,
        events: Marshal.dump(attempt.events)
      })
      nil
    end
    
    def init_engine
      Log.info "Initializing events store database schema..."
      unless @connection.table_exists? @options[:table]
        Log.debug "Creating table: #{@options[:table]}"
        @connection.create_table @options[:table] do
          String :stream_id, :size => 50, :null=>false, :index => true
          String :commit_id, :primary_key=>true, :size => 50, :null=>false
          Integer :commit_sequence, :null=>false
          Integer :stream_revision, :null=>false
          DateTime :commit_timestamp, :null=>false
          Boolean :has_been_dispatched, :null=>false, :default => false
          Blob :events, :null=>false
        end
      end
      @storage = @connection[@options[:table]]
      prepare_statements @storage
      @initialized = true
    end
    
    def purge
      Log.warn "Purging event store..."
      @storage.delete
      nil
    end
    
    private
      def ensure_initialized!
        raise EngineNotInitialized.new unless @initialized
      end
      
      def map_to_commits(commits)
        commits.map { |c| map_commit(c) }
      end
      
      def map_commit(commit_hash)
        EventStore::Commit.new stream_id: commit_hash[:stream_id],
          commit_id: commit_hash[:commit_id],
          commit_sequence: commit_hash[:commit_sequence],
          stream_revision: commit_hash[:stream_revision],
          commit_timestamp: commit_hash[:commit_timestamp].utc,
          events: Marshal.load(commit_hash[:events])
      end
      
      def prepare_statements storage
        storage.prepare(:insert, :insert_new_commit, {
          stream_id: :$stream_id, 
          commit_id: :$commit_id,
          commit_sequence: :$commit_sequence,
          stream_revision: :$stream_revision,
          commit_timestamp: :$commit_timestamp,
          events: :$events
        })
        storage.
          filter(commit_id: :$commit_id).
          prepare(:update, :mark_as_dispatched, :has_been_dispatched => true)
        storage.
          filter(stream_id: :$stream_id).
          order(:commit_sequence).
          prepare(:select, :select_from_stream)
        storage.
          filter(has_been_dispatched: false).
          order(:stream_id).order_append(:commit_sequence).
          prepare(:select, :select_undispatched)
      end
  end
end