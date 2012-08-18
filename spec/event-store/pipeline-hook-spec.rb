require 'spec-helper'

describe EventStore::Hooks::PipelineHook do
  describe "initialize" do
    it "should assign block to post_commit hook" do
      commit = mock(:commit)
      expect { |block|
        hook = described_class.new &block
        hook.post_commit commit
      }.to yield_with_args commit
    end
  end
  
  describe "post_commit" do
    it "should call post_commit lambda" do
      commit = mock(:commit)
      post_commit_hook = mock(:post_commit_hook)
      post_commit_hook.should_receive(:call).with(commit)
      hook = described_class.new :post_commit => post_commit_hook
      hook.post_commit commit
    end
  end
end