require 'spec-helper'

describe EventStore::UnitOfWork do
  let(:persistence_engine) { mock(:persistence_engine) }
  let(:event_store) { mock(:event_store, persistence_engine: persistence_engine) }
  let(:dispatcher_hook) { mock(:dispatcher_hook) }
  let(:deferred_dispatcher_hook) { mock(:deferred_dispatcher_hook) }
  
  subject { described_class.new event_store, dispatcher_hook }
  
  describe "open_stream" do
    let(:stream) { mock(:stream) }
    
    before(:each) do
      EventStore::Hooks::DeferredDispatcherHook.should_receive(:new).with(dispatcher_hook).and_return(deferred_dispatcher_hook)
    end
    
    it "should return new stream instance with deferred_dispatcher_hook" do
      EventStore::EventStream.should_receive(:new) do |stream_id, persistence_engine, options|
        stream_id.should eql 'stream-993'
        persistence_engine.should be persistence_engine
        options.should include(:hooks)
        options[:hooks][0].should be deferred_dispatcher_hook
        stream
      end
      
      subject.open_stream('stream-993').should be stream
    end
    
    it "should return same stream instance if already opened" do
      EventStore::EventStream.stub(:new).once.and_return(stream)
      subject.open_stream('stream-993').should be stream
      subject.open_stream('stream-993').should be stream
    end
  end
  
  describe "commit_changes" do
    let(:stream_1) { mock(:stream_1) }
    let(:stream_2) { mock(:stream_2) }
    let(:stream_3) { mock(:stream_3) }
    
    
    before(:each) do
      EventStore::Hooks::DeferredDispatcherHook.stub(:new).and_return(deferred_dispatcher_hook)
      EventStore::EventStream.should_receive(:new).with('stream-1', anything, anything).and_return(stream_1)
      EventStore::EventStream.should_receive(:new).with('stream-2', anything, anything).and_return(stream_2)
      EventStore::EventStream.should_receive(:new).with('stream-3', anything, anything).and_return(stream_3)
    end
    
    it "should commit_changes of each opened stream and then dispatch deferred commits" do
      headers = {header1: 'header-1', header2: 'header-2'}
      subject.open_stream('stream-1')
      subject.open_stream('stream-2')
      subject.open_stream('stream-3')
      
      stream_1.should_receive(:commit_changes).with(headers)
      stream_2.should_receive(:commit_changes).with(headers)
      stream_3.should_receive(:commit_changes).with(headers)
      deferred_dispatcher_hook.should_receive(:dispatch_deferred)
      subject.commit_changes(headers)
    end
  end
end