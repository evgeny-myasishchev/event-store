require 'spec-helper'

describe EventStore::Dispatcher::SynchronousDispatcher do
  describe "dispatch" do
    it "should dispatch the commit immediatelly to the receiver" do
      commit = double(:commit)
      expect {|receiver|
        dispatcher = described_class.new(&receiver)
        dispatcher.dispatch(commit)
      }.to yield_with_args(commit)
    end
  end
end