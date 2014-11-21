require 'spec-helper'

describe 'EventStore::Base integration' do
  subject {
    engine = EventStore::Persistence::Engines::SqlEngine.new(RSpec.configuration.database_config, {:orm_log_level => :debug})
    engine.init_engine
    engine.purge
    
    EventStore::Bootstrap.bootstrap do |with|
      with.persistence engine
      with.synchronous_dispatcher { |commit|  }
    end
  }
  
  describe 'open_stream' do
    it 'should return new stream if opening not existing stream' do
      stream = subject.open_stream 'not-existing'
      expect(stream.new_stream?).to be_truthy
    end
    
    it 'should return the stream populated with all events' do
      original_stream = subject.open_stream 'stream-221'
      evt1 = EventStore::EventMessage.new :evt1 => true
      evt2 = EventStore::EventMessage.new :evt2 => true
      evt3 = EventStore::EventMessage.new :evt2 => true
      original_stream.add evt1
      original_stream.add evt2
      original_stream.commit_changes
      original_stream.add evt3
      original_stream.commit_changes
      
      opened_stream = subject.open_stream 'stream-221'
      expect(opened_stream.committed_events.length).to eql 3
      expect(opened_stream.committed_events[0]).to eql evt1
      expect(opened_stream.committed_events[1]).to eql evt2
      expect(opened_stream.committed_events[2]).to eql evt3
      expect(opened_stream.commit_sequence).to eql 2
      expect(opened_stream.stream_revision).to eql 3
    end
    
    describe 'with min_revision' do
      let(:evt1) { EventStore::EventMessage.new :evt1 => true }
      let(:evt2) { EventStore::EventMessage.new :evt2 => true }
      let(:evt3) { EventStore::EventMessage.new :evt2 => true }
      let(:evt4) { EventStore::EventMessage.new :evt2 => true }
      let(:evt5) { EventStore::EventMessage.new :evt2 => true }
      let(:evt6) { EventStore::EventMessage.new :evt2 => true }
      
      before(:each) do
        original_stream = subject.open_stream 'stream-221'
        original_stream.add evt1
        original_stream.commit_changes
        original_stream.add evt2
        original_stream.add evt3
        original_stream.commit_changes
        original_stream.add evt4
        original_stream.add evt5
        original_stream.add evt6
        original_stream.commit_changes
      end
      
      it 'should return the stream populated with all events starting from specified revision' do
        stream = subject.open_stream 'stream-221', min_revision: 2
        expect(stream.committed_events.length).to eql 5
        expect(stream.committed_events[0]).to eql evt2
        expect(stream.committed_events[1]).to eql evt3
        expect(stream.committed_events[2]).to eql evt4
        expect(stream.committed_events[3]).to eql evt5
        expect(stream.committed_events[4]).to eql evt6
        expect(stream.stream_revision).to eql 6
        expect(stream.commit_sequence).to eql 3
      end
      
      it 'should skip events if stream revision is between start and end events of the commit' do
        stream = subject.open_stream 'stream-221', min_revision: 3
        expect(stream.committed_events.length).to eql 4
        expect(stream.committed_events[0]).to eql evt3
        expect(stream.committed_events[1]).to eql evt4
        expect(stream.committed_events[2]).to eql evt5
        expect(stream.committed_events[3]).to eql evt6
        expect(stream.stream_revision).to eql 6
        expect(stream.commit_sequence).to eql 3
        
        stream = subject.open_stream 'stream-221', min_revision: 6
        expect(stream.committed_events.length).to eql 1
        expect(stream.committed_events[0]).to eql evt6
        expect(stream.stream_revision).to eql 6
        expect(stream.commit_sequence).to eql 3
      end
    end
  end
end