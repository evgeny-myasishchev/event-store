require 'spec-helper'

describe EventStore::Hooks::DispatcherHook do
  let(:commit) { double(:commit, :commit_id => "commit-1") }
  let(:dispatcher) { double(:dispatcher) }
  let(:persistence_engine) { double(:persistence_engine) }
  let(:hook) { described_class.new dispatcher, persistence_engine }
  
  describe "post_commit" do
    it "should dispatch commit and mark it as dispatched on success" do
      expect(dispatcher).to receive(:dispatch).with(commit)
      expect(persistence_engine).to receive(:mark_commit_as_dispatched).with(commit)
      hook.post_commit(commit)
    end
    
    it "should dispatch commit but don't mark it as dispached if failed" do
      expect(dispatcher).to receive(:dispatch).with(commit).and_raise("some-error")
      expect(persistence_engine).not_to receive(:mark_commit_as_dispatched).with(commit)
      
      expect(lambda { hook.post_commit(commit) }).to raise_error("some-error")
    end
  end
end