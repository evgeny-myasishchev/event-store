require 'spec-helper'

describe EventStore::Base do
  let(:persistence_engine) { EventStore::Persistence::Engines::InMemoryEngine }
  let(:store) { described_class.new(persistence_engine) }

  describe 'for_each_commit' do
    it 'should be delegated to persistence_engine' do
      commit = double(:commit)
      expect(persistence_engine).to receive(:for_each_commit) do |&block|
        block.call commit
      end
      store.for_each_commit do |c|
        expect(c).to be commit
      end
    end
  end
  
  describe "stream_exists?" do
    it "should use persistence engine to check if the stream exists" do
      expect(persistence_engine).to receive(:exists?).with('stream-992').and_return(true)
      expect(store.stream_exists?('stream-992')).to be_truthy
    end
  end
  
  describe "create_stream" do
    it "should create stream with persistence engine" do
      mock_stream = double(:stream)
      expect(EventStore::EventStream).to receive(:open_stream) do |stream_id, pe, options|
        expect(stream_id).to eql "some-stream-id"
        expect(pe).to be persistence_engine
        mock_stream
      end
      expect(store.open_stream("some-stream-id")).to eql mock_stream
    end
  end
    
  describe "open_stream" do
    it "should open stream with persistence engine" do
      mock_stream = double(:stream)
      expect(EventStore::EventStream).to receive(:open_stream) do |stream_id, pe, options|
        expect(stream_id).to eql "some-stream-id"
        expect(pe).to be persistence_engine
        mock_stream
      end
      expect(store.open_stream("some-stream-id")).to eql mock_stream
    end
      
    it "should handle min_revision option when initializing" do
      mock_stream = double(:stream)
      expect(EventStore::EventStream).to receive(:open_stream) do |stream_id, pe, options|
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