require 'spec-helper'

describe EventStore::Hooks::DeferredDispatcherHook do
  let(:original_hook) { double(:original_hook) }
  let(:commit_1) { double(:commit_1) }
  let(:commit_2) { double(:commit_2) }
  subject { described_class.new(original_hook) }
  
  it "should remember each commit on post_commit stage and dispatch it to original hook on dispatch_deferred" do
    subject.post_commit(commit_1)
    subject.post_commit(commit_2)
    
    original_hook.should_receive(:post_commit).with(commit_1)
    original_hook.should_receive(:post_commit).with(commit_2)
    
    subject.dispatch_deferred
  end
end