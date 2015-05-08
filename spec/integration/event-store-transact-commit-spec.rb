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
  
  describe 'transact commit' do
    it 'should rollback if any commit fails' do
      evt1 = EventStore::EventMessage.new :evt1 => true
      
      stream1 = subject.open_stream 'stream-221'
      stream1.add evt1
      
      stream2 = subject.open_stream 'stream-221'
      stream2.add evt1
      expect {
        subject.transaction do |t|
          stream1.commit_changes t
          stream2.commit_changes t
        end
      }.to raise_error EventStore::ConcurrencyError
      
      actual_stream = subject.open_stream 'stream-221'
      expect(actual_stream.stream_revision).to eql 0
      expect(actual_stream.commit_sequence).to eql 0
    end
  end
end