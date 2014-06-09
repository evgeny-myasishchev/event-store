require 'spec-helper'

describe EventStore::Base do
  let(:persistence_engine) { double(:persistence_engine) }
  let(:dispatcher) { double(:dispatcher) }
  let(:store) { described_class.new(persistence_engine, dispatcher) }
  
  describe "dispatch_undispatched" do
    it "should get all undispatched commits from persistence_engine, dispatch them and mark them as dispatched" do
      commit1 = double("commit-1", :commit_id => "commit-1")
      commit2 = double("commit-2", :commit_id => "commit-2")
      
      expect(persistence_engine).to receive(:get_undispatched_commits).and_return([commit1, commit2])
      expect(dispatcher).to receive(:dispatch).with(commit1)
      expect(dispatcher).to receive(:dispatch).with(commit2)
      expect(persistence_engine).to receive(:mark_commit_as_dispatched).with(commit1)
      expect(persistence_engine).to receive(:mark_commit_as_dispatched).with(commit2)
      
      store.dispatch_undispatched
    end
  end
  
  describe "stream_exists?" do
    it "should use persistence engine to check if the stream exists" do
      expect(persistence_engine).to receive(:exists?).with('stream-992').and_return(true)
      expect(store.stream_exists?('stream-992')).to be_truthy
    end
  end
  
  describe "open_stream" do
    it "should initialize a new stream with persistence engine and dispatcher hook" do
      mock_stream = double(:stream)
      expect(EventStore::EventStream).to receive(:new) do |stream_id, pe, options|
        expect(stream_id).to eql "some-stream-id"
        expect(pe).to be persistence_engine
        expect(options[:hooks].length).to eql(1)
        expect(options[:hooks][0]).to be_instance_of(EventStore::Hooks::DispatcherHook)
        expect(options[:hooks][0].dispatcher).to be dispatcher
        expect(options[:hooks][0].persistence_engine).to be persistence_engine
        mock_stream
      end
      expect(store.open_stream("some-stream-id")).to eql mock_stream
    end
  end
  
  describe "purge" do
    it "should use persistence engine to purge the stream" do
      expect(persistence_engine).to receive(:purge)
      store.purge
    end
  end
  
  describe "begin_work" do
    let(:work) { double(:work, commit_changes: nil) }
    before(:each) do
      expect(EventStore::UnitOfWork).to receive(:new).with(store, store.dispatcher_hook).and_return(work)
    end
    it "should start a new work and commit changes" do
      expect(work).to receive(:commit_changes)
      store.begin_work do |w|
        expect(w).to be work
      end
    end
    
    it "should commit changes with headers if supplied" do
      headers = {header1: 'header-1'}
      expect(work).to receive(:commit_changes).with(headers)
      store.begin_work headers do |w|
        expect(w).to be work
      end
    end
    
    it "should return nil if block given" do
      expect(store.begin_work do |w|
      end).to be_nil
    end
    
    it "should just start a new work and return it if no block given" do
      expect(work).not_to receive(:commit_changes)
      expect(store.begin_work).to be(work)
    end
  end
end