require 'spec-helper'

describe 'EventStore::Base integration' do
  subject {
    EventStore::Bootstrap.bootstrap do |with|
      with.sql_persistence(RSpec.configuration.database_config, {:orm_log_level => :debug}).compress.engine.purge
      with.synchronous_dispatcher { |commit|  }
    end
  }
  
  describe 'compression' do
    it 'should correctly persist and retrieve stream events' do
      original_stream = subject.open_stream 'stream-221'
      evt1 = EventStore::EventMessage.new({:evt1 => true}, {header1: 'value-1'})
      evt2 = EventStore::EventMessage.new({:evt2 => true}, {header2: 'value-2'})
      original_stream.add evt1
      original_stream.add evt2
      original_stream.commit_changes
      
      opened_stream = subject.open_stream 'stream-221'
      expect(opened_stream.committed_events.length).to eql 2
      expect(opened_stream.committed_events[0]).to eql evt1
      expect(opened_stream.committed_events[1]).to eql evt2
    end
  end
end