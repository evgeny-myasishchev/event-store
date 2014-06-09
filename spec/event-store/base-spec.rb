require 'spec-helper'

describe EventStore::Base do
  let(:persistence_engine) { double(:persistence_engine) }
  let(:dispatcher) { double(:dispatcher) }
  let(:store) { described_class.new(persistence_engine, dispatcher) }
  
  describe "dispatch_undispatched" do
    it "should get all undispatched commits from persistence_engine, dispatch them and mark them as dispatched" do
      commit1 = double("commit-1", :commit_id => "commit-1")
      commit2 = double("commit-2", :commit_id => "commit-2")
      
      persistence_engine.should_receive(:get_undispatched_commits).and_return([commit1, commit2])
      dispatcher.should_receive(:dispatch).with(commit1)
      dispatcher.should_receive(:dispatch).with(commit2)
      persistence_engine.should_receive(:mark_commit_as_dispatched).with(commit1)
      persistence_engine.should_receive(:mark_commit_as_dispatched).with(commit2)
      
      store.dispatch_undispatched
    end
  end
  
  describe "stream_exists?" do
    it "should use persistence engine to check if the stream exists" do
      persistence_engine.should_receive(:exists?).with('stream-992').and_return(true)
      store.stream_exists?('stream-992').should be_truthy
    end
  end
  
  describe "open_stream" do
    it "should initialize a new stream with persistence engine and dispatcher hook" do
      mock_stream = double(:stream)
      EventStore::EventStream.should_receive(:new) do |stream_id, pe, options|
        stream_id.should eql "some-stream-id"
        pe.should be persistence_engine
        options[:hooks].length.should eql(1)
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
    let(:work) { double(:work, commit_changes: nil) }
    before(:each) do
      EventStore::UnitOfWork.should_receive(:new).with(store, store.dispatcher_hook).and_return(work)
    end
    it "should start a new work and commit changes" do
      work.should_receive(:commit_changes)
      store.begin_work do |w|
        w.should be work
      end
    end
    
    it "should commit changes with headers if supplied" do
      headers = {header1: 'header-1'}
      work.should_receive(:commit_changes).with(headers)
      store.begin_work headers do |w|
        w.should be work
      end
    end
    
    it "should return nil if block given" do
      store.begin_work do |w|
      end.should be_nil
    end
    
    it "should just start a new work and return it if no block given" do
      work.should_not_receive(:commit_changes)
      store.begin_work.should be(work)
    end
  end
end