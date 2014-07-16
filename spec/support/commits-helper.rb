module Support::CommitsHelper
  
  def new_event(body)
    EventStore::EventMessage.new body
  end
  
  #*args are possible events
  def build_commit(stream_id, commit_id, *args, &block)
    @stream_revision ||= {}
    @stream_commit_sequence ||= {}

    next_revision = (@stream_revision[stream_id] || 0) + (args.length == 0 ? 1 : args.length)
    @stream_revision[stream_id] = next_revision
    next_commit_sequence = (@stream_commit_sequence[stream_id] || 0) + 1
    @stream_commit_sequence[stream_id] = next_commit_sequence

    commit_args = {
      :stream_id => stream_id,
      :commit_id => commit_id,
      :events => args,
      :commit_sequence => next_commit_sequence,
      :stream_revision => next_revision
    }
    yield commit_args if block_given?
    EventStore::Commit.new commit_args
  end
  
  def commit_all(persistence, *args)
    args.each { |commit| persistence.commit(commit) }
  end
end