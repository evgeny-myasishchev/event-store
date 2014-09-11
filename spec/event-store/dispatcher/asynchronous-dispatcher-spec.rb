require 'spec-helper'

describe EventStore::Dispatcher::AsynchronousDispatcher do
  describe 'schedule_dispatch' do
    it 'should dispatch the commit in an non-blocking way' do
      commit = double(:commit, commit_id: 'c1')
      is_dispatched = false
      mutex = Mutex.new
      resource = ConditionVariable.new
      receiver = ->(c) { 
        expect(c).to be commit
        mutex.synchronize { 
          is_dispatched = true 
          resource.signal
        }
      }
      subject = described_class.new &receiver
      subject.schedule_dispatch commit
      mutex.synchronize {
        resource.wait(mutex, 2)
        expect(is_dispatched).to be_truthy
      }
    end
  end
  
  describe 'wait_pending' do
    it 'should wait for pending commits to be dispatched' do
      c1, c2 = EventStore::Commit.new(stream_id: 's-1'), EventStore::Commit.new(stream_id: 's-1')
      is_dispatched = false
      receiver = ->(c) { 
        is_dispatched = true if c == c2
      }
      subject = described_class.new &receiver
      subject.schedule_dispatch c1
      subject.schedule_dispatch c2
      subject.wait_pending
      expect(is_dispatched).to be_truthy
    end
  end
  
  describe 'stop' do
    it 'should stop the worker queue dispatching all pending commits blocking current thread' do
      c1, c2 = EventStore::Commit.new(stream_id: 's-1'), EventStore::Commit.new(stream_id: 's-1')
      is_dispatched = false
      receiver = ->(c) { 
        is_dispatched = true if c == c2
      }
      subject = described_class.new &receiver
      subject.schedule_dispatch c1
      subject.schedule_dispatch c2
      subject.stop
      expect(is_dispatched).to be_truthy
    end
  end
  
  describe 'restart' do
    it 'should start new worker' do
      c1 = EventStore::Commit.new(stream_id: 's-1')
      is_dispatched = false
      receiver = ->(c) { 
        is_dispatched = true if c == c1
      }
      subject = described_class.new &receiver
      subject.stop
      subject.restart
      subject.schedule_dispatch c1
      subject.wait_pending
      expect(is_dispatched).to be_truthy
    end
    
    it 'should fail to restart if not stopped' do
      subject = described_class.new {}
      expect { subject.restart }.to raise_error(/Failed to restart\. The worker is still running\. Status: \w+./)
    end
  end
end