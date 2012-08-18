require 'spec-helper'

describe EventStore::Hooks::DispatcherHook do
  let(:commit) { mock(:commit, :commit_id => "commit-1") }
  let(:dispatcher) { mock(:dispatcher) }
  let(:persistence_engine) { mock(:persistence_engine) }
  let(:hook) { described_class.new dispatcher, persistence_engine }
  
  describe "post_commit" do
    it "should dispatch commit and mark it as dispatched on success" do
      dispatcher.should_receive(:dispatch).with(commit)
      persistence_engine.should_receive(:mark_commit_as_dispatched).with(commit)
      hook.post_commit(commit)
    end
    
    it "should dispatch commit but don't mark it as dispached if failed" do
      dispatcher.should_receive(:dispatch).with(commit).and_raise("some-error")
      persistence_engine.should_not_receive(:mark_commit_as_dispatched).with(commit)
      
      lambda { hook.post_commit(commit) }.should raise_error("some-error")
    end
  end
end