require 'spec-helper'

describe EventStore::Bootstrap do
  describe "bootstrap" do
    it "should raise BootstrapError if no persistence" do
      lambda { 
        described_class.bootstrap do |with|
          with.synchorous_dispatcher {}
        end
      }.should raise_error(EventStore::Bootstrap::BootstrapError)
    end
    
    it "should raise BootstrapError if no dispatcher" do
      lambda { 
        described_class.bootstrap do |with|
          with.in_memory_persistence
        end
      }.should raise_error(EventStore::Bootstrap::BootstrapError)
    end
    
    it "should create new event store" do
      store = described_class.bootstrap do |with|
        with.in_memory_persistence
        with.synchorous_dispatcher {}
      end
      store.should be_instance_of(EventStore::Base)
    end
    
    it "should not dispatch_undispatched immediatelly" do
      store = double(:store)
      EventStore::Base.stub(:new) {store}
      store.should_not_receive(:dispatch_undispatched)
      described_class.bootstrap do |with|
        with.in_memory_persistence
        with.synchorous_dispatcher {}
      end
    end
  end
end