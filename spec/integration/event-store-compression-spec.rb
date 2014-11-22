require 'spec-helper'

describe 'EventStore::Base integration' do
  subject {
    store = EventStore::Bootstrap.bootstrap do |with|
      with.sql_persistence(RSpec.configuration.database_config, {:orm_log_level => :debug}).compress
      with.synchronous_dispatcher { |commit|  }
    end
    store.purge
    store
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
    
    it 'should persist correctly large events' do
      evt = EventStore::EventMessage.new({
        attrib1: 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        attrib2: 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
      })
      stream = subject.open_stream 'stream-222'
      stream.add evt
      stream.commit_changes
      expect(subject.open_stream('stream-222').committed_events).to include evt
    end
    
    it 'should persist correctly large headers' do
      evt = EventStore::EventMessage.new({}, {
        header1: 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        header1: 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
      })
      stream = subject.open_stream 'stream-222'
      stream.add evt
      stream.commit_changes
      stream = subject.open_stream 'stream-222'
      expect(subject.open_stream('stream-222').committed_events).to include evt
    end
  end
end