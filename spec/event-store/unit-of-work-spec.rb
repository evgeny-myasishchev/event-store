require 'spec-helper'

describe EventStore::UnitOfWork do
  let(:persistence_engine) { double(:persistence_engine) }
  let(:event_store) { double(:event_store, persistence_engine: persistence_engine) }
  let(:dispatcher_hook) { double(:dispatcher_hook) }
  let(:deferred_dispatcher_hook) { double(:deferred_dispatcher_hook) }
  
  subject { described_class.new event_store, dispatcher_hook }
  
  describe "stream_exists?" do
    it "should use event store to check if it exists" do
      expect(event_store).to receive(:stream_exists?).with('stream-3902').and_return(true)
      expect(subject.stream_exists?('stream-3902')).to be_truthy
    end
  end
  
  describe "open_stream" do
    let(:stream) { double(:stream) }
    
    before(:each) do
      expect(EventStore::Hooks::DeferredDispatcherHook).to receive(:new).with(dispatcher_hook).and_return(deferred_dispatcher_hook)
    end
    
    it "should return new stream instance with deferred_dispatcher_hook" do
      expect(EventStore::EventStream).to receive(:new) do |stream_id, persistence_engine, options|
        expect(stream_id).to eql 'stream-993'
        expect(persistence_engine).to be persistence_engine
        expect(options).to include(:hooks)
        expect(options[:hooks][0]).to be deferred_dispatcher_hook
        stream
      end
      
      expect(subject.open_stream('stream-993')).to be stream
    end
    
    it "should return same stream instance if already opened" do
      allow(EventStore::EventStream).to receive(:new).once.and_return(stream)
      expect(subject.open_stream('stream-993')).to be stream
      expect(subject.open_stream('stream-993')).to be stream
    end
  end
  
  describe "commit_changes" do
    let(:stream_1) { double(:stream_1) }
    let(:stream_2) { double(:stream_2) }
    let(:stream_3) { double(:stream_3) }
    
    
    before(:each) do
      allow(EventStore::Hooks::DeferredDispatcherHook).to receive(:new).and_return(deferred_dispatcher_hook)
      expect(EventStore::EventStream).to receive(:new).with('stream-1', anything, anything).and_return(stream_1)
      expect(EventStore::EventStream).to receive(:new).with('stream-2', anything, anything).and_return(stream_2)
      expect(EventStore::EventStream).to receive(:new).with('stream-3', anything, anything).and_return(stream_3)
    end
    
    it "should commit_changes of each opened stream and then dispatch deferred commits" do
      headers = {header1: 'header-1', header2: 'header-2'}
      subject.open_stream('stream-1')
      subject.open_stream('stream-2')
      subject.open_stream('stream-3')
      
      expect(stream_1).to receive(:commit_changes).with(headers)
      expect(stream_2).to receive(:commit_changes).with(headers)
      expect(stream_3).to receive(:commit_changes).with(headers)
      expect(deferred_dispatcher_hook).to receive(:dispatch_deferred)
      subject.commit_changes(headers)
    end
  end
end