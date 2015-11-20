module Support::CommitsHelper
  
  def new_event(body)
    EventStore::EventMessage.new body
  end
  
  #*args are possible events
  def build_commit(stream_id, commit_id, *args, &block)
    @stream_revision ||= Hash.new(0)
    @stream_commit_sequence ||= Hash.new(0)

    #Sometimes we need an empty commit but revision should increment anyway to prevent optimistic concurrency errors
    #so if no events then the revision is 1.
    @stream_revision[stream_id] = @stream_revision[stream_id] + (args.length == 0 ? 1 : args.length) 
    @stream_commit_sequence[stream_id] = @stream_commit_sequence[stream_id] + 1

    commit_args = {
      :stream_id => stream_id,
      :commit_id => commit_id,
      :events => args,
      :commit_sequence => @stream_commit_sequence[stream_id],
      :stream_revision => @stream_revision[stream_id]
    }
    yield commit_args if block_given?
    EventStore::Commit.new commit_args
  end
  
  def commit_all(persistence, *args)
    args.map { |commit| persistence.commit(commit) }
  end
end