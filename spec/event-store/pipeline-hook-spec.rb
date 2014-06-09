require 'spec-helper'

describe EventStore::Hooks::PipelineHook do
  describe "initialize" do
    it "should assign block to post_commit hook" do
      commit = double(:commit)
      expect { |block|
        hook = described_class.new &block
        hook.post_commit commit
      }.to yield_with_args commit
    end
  end
  
  describe "post_commit" do
    it "should call post_commit lambda" do
      commit = double(:commit)
      post_commit_hook = double(:post_commit_hook)
      expect(post_commit_hook).to receive(:call).with(commit)
      hook = described_class.new :post_commit => post_commit_hook
      hook.post_commit commit
    end
  end
end