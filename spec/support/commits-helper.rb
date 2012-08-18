module Support::CommitsHelper
  
  def new_event(body)
    Xtms::EventStore::EventMessage.new body
  end
  
  #*args are possible events
  def build_commit(stream_id, commit_id, *args, &block)
    commit_args = {
      :stream_id => stream_id,
      :commit_id => commit_id,
      :events => args
    }
    yield commit_args if block_given?
    Xtms::EventStore::Commit.new commit_args
  end
  
  def commit_all(stream, *args)
    args.each { |commit| stream.commit(commit) }
  end
end