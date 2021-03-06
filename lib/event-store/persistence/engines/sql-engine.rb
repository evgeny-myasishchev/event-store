require 'sequel'

module EventStore::Persistence::Engines
  
  class SqlEngine < EventStore::Persistence::PersistenceEngine
    class EngineNotInitialized < ::StandardError
      def initialize
        super("The engine has not been initialized. Please make sure the engine is initialized prior to using it. Initialization can be done with 'init_engine' method")
      end
    end
    
    include EventStore::Loggable
    
    attr_reader :connection
    
    # 
    # connection_specification - Connection specification for Sequel
    # See here: http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html
    # 
    def initialize(connection_specification = {}, options = {})
      raise ArgumentError.new 'Connection specification can not be nil' if connection_specification.nil?
      connection_specification = connection_specification.dup
      @options = {
        table: :'event-store-commits',
        orm_log_level: :debug,
        serializer: self.class.default_serializer
      }.merge! options
      
      @connection = Sequel.connect connection_specification
      @connection.extension(:pagination)
      @connection.loggers << EventStore::Logging::Logger.get("#{self.class.name}::Sequel")
      @connection.sql_log_level = @options[:orm_log_level]
      
      @initialized = false
    end
    
    def supports_transactions?
      true
    end
    
    def transaction(&block)
      @connection.transaction do
        yield
      end
    end
    
    def exists?(stream_id)
      ensure_initialized!
      !@storage.where(stream_id: stream_id).empty?
    end
    
    def get_from(stream_id, min_revision: nil)
      ensure_initialized!
      map_to_commits @connection.call(:select_from_stream, stream_id: stream_id, min_revision: min_revision)
    end
    
    def get_head(stream_id)
      ensure_initialized!
      head = @storage.where(stream_id: stream_id)
        .select(Sequel.lit('max(commit_sequence) commit_sequence, max(stream_revision) stream_revision')).first
      head[:commit_sequence] = 0 if head[:commit_sequence].nil?
      head[:stream_revision] = 0 if head[:stream_revision].nil?
      head
    end
    
    def for_each_commit(checkpoint: nil, &block)
      ensure_initialized!
      
      #Fetching in pages to prevent entire dataset from being loaded into memory
      query = @storage
      query = query.where('checkpoint_number > :checkpoint', checkpoint: checkpoint) unless checkpoint.nil?
      query
        .order(:checkpoint_number)
        .each_page(1000) { |page| 
          page.to_a.each { |c| yield map_commit(c) }
        }
      nil
    end

    #Writes the to-be-commited events provided to the underlying persistence mechanism.
    # * attempt - the series of events and associated metadata to be commited.
    def commit(attempt)
      ensure_initialized!
      Log.debug("Committing attempt #{attempt}")
      begin
        checkpoint = @storage.insert({
          stream_id: attempt.stream_id,
          commit_id: attempt.commit_id,
          commit_sequence: attempt.commit_sequence,
          stream_revision: attempt.stream_revision,
          commit_timestamp: attempt.commit_timestamp,
          events: Sequel.blob(serializer.serialize(attempt.events)),
          headers: Sequel.blob(serializer.serialize(attempt.headers))
        })
      rescue Sequel::UniqueConstraintViolation => e
        Log.error "Constraint violation error occured: #{e}."
        raise EventStore::ConcurrencyError.new e
      end
      EventStore::Commit.new attempt.hash.merge checkpoint: checkpoint
    end
    
    def init_engine
      Log.info "Initializing events store database schema..."
      unless @connection.table_exists? @options[:table]
        Log.debug "Creating table: #{@options[:table]}"
        @connection.create_table @options[:table] do
          primary_key :checkpoint_number, type: Bignum
          String :stream_id, :size => 50, :null=>false
          String :commit_id, :size => 50, :null=>false
          Integer :commit_sequence, :null=>false
          Integer :stream_revision, :null=>false
          DateTime :commit_timestamp, :null=>false
          File :events, :null=>false
          File :headers, :null=>false
          index [:stream_id, :commit_sequence], unique: true
          index [:stream_id, :commit_id], unique: true
          index [:stream_id, :stream_revision], unique: true
        end
      end
      @storage = @connection[@options[:table]]
      prepare_statements @storage
      @initialized = true
    end
    
    def purge!
      Log.warn "Purging event store..."
      @storage.delete
      nil
    end
    
    def serializer
      @options[:serializer]
    end
    
    def serializer=(value)
      @options[:serializer] = value
    end
    
    def self.default_serializer
      EventStore::Persistence::Serializers::YamlSerializer.new
    end
    
    private
      def ensure_initialized!
        raise EngineNotInitialized.new unless @initialized
      end
      
      def map_to_commits(commits)
        commits.map { |c| map_commit(c) }
      end
      
      def map_commit(commit_hash)
        EventStore::Commit.new checkpoint: commit_hash[:checkpoint_number],
          stream_id: commit_hash[:stream_id],
          commit_id: commit_hash[:commit_id],
          commit_sequence: commit_hash[:commit_sequence],
          stream_revision: commit_hash[:stream_revision],
          commit_timestamp: commit_hash[:commit_timestamp].utc,
          events: serializer.deserialize(Sequel.blob(commit_hash[:events])),
          headers: serializer.deserialize(Sequel.blob(commit_hash[:headers]))
      end
      
      def prepare_statements storage
        storage.
          where('stream_id = :stream_id and (stream_revision >= :min_revision or :min_revision is NULL)', stream_id: :$stream_id, min_revision: :$min_revision).
          order(:checkpoint_number).
          prepare(:select, :select_from_stream)
      end
  end
end