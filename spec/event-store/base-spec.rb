require 'spec-helper'

describe EventStore::Base do
  let(:persistence_engine) { mock(:persistence_engine) }
  let(:dispatcher) { mock(:dispatcher) }
  let(:store) { described_class.new(persistence_engine, dispatcher) }
  
  describe "dispatch_undispatched" do
    it "should get all undispatched commits from persistence_engine, dispatch them and mark them as dispatched" do
      commit1 = mock("commit-1", :commit_id => "commit-1")
      commit2 = mock("commit-2", :commit_id => "commit-2")
      
      persistence_engine.should_receive(:get_undispatched_commits).and_return([commit1, commit2])
      dispatcher.should_receive(:dispatch).with(commit1)
      dispatcher.should_receive(:dispatch).with(commit2)
      persistence_engine.should_receive(:mark_commit_as_dispatched).with(commit1)
      persistence_engine.should_receive(:mark_commit_as_dispatched).with(commit2)
      
      store.dispatch_undispatched
    end
  end
  
  describe "open_stream" do
    it "should initialize a new stream with persistence engine and dispatcher hook" do
      mock_stream = mock(:stream)
      EventStore::EventStream.should_receive(:new) do |stream_id, pe, options|
        stream_id.should eql "some-stream-id"
        pe.should be persistence_engine
        options[:hooks].should have(1).elements
        options[:hooks][0].should be_instance_of(EventStore::Hooks::DispatcherHook)
        options[:hooks][0].dispatcher.should be dispatcher
        options[:hooks][0].persistence_engine.should be persistence_engine
        mock_stream
      end
      store.open_stream("some-stream-id").should eql mock_stream
    end
  end
  
  describe "purge" do
    it "should use persistence engine to purge the stream" do
      persistence_engine.should_receive(:purge)
      store.purge
    end
  end
  
  describe "begin_work" do
    it "should start a new work and commit changes" do
      work = mock(:work)
      EventStore::UnitOfWork.should_receive(:new).with(store, store.dispatcher_hook).and_return(work)
      work.should_receive(:commit_changes)
      store.begin_work do |w|
        w.should be work
      end
    end
  end
end