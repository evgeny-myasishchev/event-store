require 'spec-helper'

describe EventStore::Dispatcher::AsynchronousDispatcher do
  describe 'schedule_dispatch' do
    it 'should dispatch the commit in an non-blocking way' do
      commit = double(:commit)
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
end