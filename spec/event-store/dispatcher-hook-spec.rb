require 'spec-helper'

describe EventStore::Hooks::DispatcherHook do
  let(:commit) { double(:commit, :commit_id => 'commit-1') }
  let(:dispatcher) { EventStore::Dispatcher::Base.new }
  let(:persistence_engine) { double(:persistence_engine) }
  let(:hook) { described_class.new dispatcher, persistence_engine }
  
  it 'should hook into the dispatcher pipeline and mark commit as dispatched on after_dispatch' do
    allow(dispatcher).to receive(:dispatch_immediately)
    expect(persistence_engine).to receive(:mark_commit_as_dispatched).with(commit)
    hook.post_commit(commit)
  end
  
  describe 'post_commit' do
    it 'should schedule dispatch' do
      expect(dispatcher).to receive(:schedule_dispatch).with(commit)
      hook.post_commit(commit)
    end
  end
end