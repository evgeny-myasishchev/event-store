require 'spec-helper'

describe EventStore::Base do
  let(:persistence_engine) { double(:persistence_engine) }
  let(:dispatcher) { double(:dispatcher, hook_into_pipeline: nil) }
  let(:store) { described_class.new(persistence_engine, dispatcher) }
  
  describe "dispatch_undispatched" do
    it "should get all undispatched commits from persistence_engine and dispatch them" do
      commit1 = double("commit-1", :commit_id => "commit-1")
      commit2 = double("commit-2", :commit_id => "commit-2")
      
      expect(persistence_engine).to receive(:get_undispatched_commits).and_return([commit1, commit2])
      expect(dispatcher).to receive(:schedule_dispatch).with(commit1)
      expect(dispatcher).to receive(:schedule_dispatch).with(commit2)
      
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
      
    it "should handle min_revision option when initializing" do
      mock_stream = double(:stream)
      expect(EventStore::EventStream).to receive(:new) do |stream_id, pe, options|
        expect(options[:min_revision]).to eql 10
        mock_stream
      end
      expect(store.open_stream("some-stream-id", min_revision: 10)).to eql mock_stream
    end
  end
  
  describe "purge" do
    it "should use persistence engine to purge the stream" do
      expect(persistence_engine).to receive(:purge)
      store.purge
    end
  end
end