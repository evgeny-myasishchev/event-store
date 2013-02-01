# Tracks a series of events and commit them to durable storage.
class EventStore::EventStream
  class InvalidStreamIdError < ::StandardError; end
  
  Log = EventStore::Logging::Logger.get 'event-store::event-stream'
  
  # Gets the value that indicates if the stream is new (no commits for the stream has been persisted yet).
  def new_stream?
    @new_stream
  end
  
  # Gets the value which uniquely identifies the stream to which the stream belongs.
	attr_reader :stream_id
	
  #Gets the value which indiciates the most recent committed revision of event stream.
  #Basically this value is the same as number of commited events in the stream. 
  #Value zero means there are no events (and commits) in the stream.
	attr_reader :stream_revision

  #Gets the value which indicates the most recent committed sequence identifier of the event stream.
  #This value is incremented each time new commit is persisted.
  #Value zero means there are commits in the stream.
	attr_reader :commit_sequence

  #Gets the collection of events which have been successfully persisted to durable storage.
	def committed_events
	  @committed_events_ro ||= EventStore::Infrastructure::ReadOnlyArray.new(@committed_events) 
	end

	#Gets the collection of yet-to-be-committed events that have not yet been persisted to durable storage.
	def uncommitted_events
	  @uncommitted_events_ro ||= EventStore::Infrastructure::ReadOnlyArray.new(@uncommitted_events) 
	end
	
	#
	# Args:
	# * stream_id - stream identifier. Can be generated with Identity::generate
	# * persistence_engine - the engine to access commits	
	#
	# options:
	# * hooks - pipeline hooks that are invoked at different stages. See PipelineHook.
	# * 
	# 
	def initialize(stream_id, persistence_engine, options = {})
	  raise InvalidStreamIdError.new "stream_id can not be null or empty" if stream_id == nil || stream_id == ""
	  @options = {
	    :hooks => []
	  }.merge!(options)
    @stream_id          = stream_id
    @persistence_engine = persistence_engine
    @uncommitted_events = []
    @pipeline_hooks     = @options[:hooks]
    
    @stream_revision    = 0
    @commit_sequence    = 0
    @committed_events   = []
    @uncommitted_events = []
    
    populate_stream_with persistence_engine.get_from(stream_id)
	end

	# Adds the event messages provided to the session to be tracked.
	#  event - The event-message to be tracked.
	def add(uncommitted_event) 
	  @uncommitted_events.push(uncommitted_event)
	  self
	end

	# Commits the changes to durable storage.
	#  => returns commit
	def commit_changes(headers = {})
	  unless uncommitted_events.length > 0
	    Log.warn "No uncommitted events found for stream '#{stream_id}'. Commit skipped."
	    return
	  end
	  Log.debug "Committing '#{stream_id}'. #{@uncommitted_events.length} uncommitted events to commit."
	  attempt = EventStore::Commit.build(self, @uncommitted_events.dup, headers)
	  @persistence_engine.commit(attempt)
    @new_stream = false #After commits are committed the stream is not new anymore
	  populate_stream_with([attempt])
	  attempt.events.each { |evt| @uncommitted_events.delete(evt) }
	  Log.debug "Processing pipeline hooks..."
	  @pipeline_hooks.each { |hook| hook.post_commit(attempt) }
	  Log.debug "Done."
	  attempt
	end
	
	private
	  def populate_stream_with(commits)
	    if commits.empty?
	      Log.debug "Opening new stream '#{stream_id}' since no commits found..."
        @new_stream = true
	      return
	    end
      @new_stream = false
	    Log.debug "Populating stream '#{stream_id}' with #{commits.length} commits..."
	    commits.each do |commit|
	      @commit_sequence = commit.commit_sequence
	      @stream_revision += commit.events.length
	      @committed_events.concat(commit.events)
	    end
	  end
end
