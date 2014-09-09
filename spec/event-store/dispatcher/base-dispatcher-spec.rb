require 'spec-helper'

describe EventStore::Dispatcher::Base do
  let(:subject) {
    Class.new(described_class) do
      attr_reader :dispatched_commits
      
      def initialize
        @dispatched_commits = []
        super
      end
      
      def dispatch_immediately(commit)
        @dispatched_commits << commit
      end
    end.new
  }
  
  describe 'schedule_dispatch' do
    let(:commit1) { double(:commit1) }
    let(:commit2) { double(:commit2) }
    
    it 'should dispatch the commit immediatelly to the receiver' do
      subject.schedule_dispatch commit1
      subject.schedule_dispatch commit2
      expect(subject.dispatched_commits).to eql [commit1, commit2]
    end
    
    it 'should trigger after_dispatch hooks' do
      hook1_invoked = false
      hook2_invoked = false
      subject.hook_into_pipeline after_dispatch: -> (c) {
        expect(c).to eql commit1
        hook1_invoked = true
      }
      subject.hook_into_pipeline after_dispatch: -> (c) {
        expect(c).to eql commit1
        hook2_invoked = true
      }
      subject.schedule_dispatch commit1
      expect(hook1_invoked).to be_truthy
      expect(hook2_invoked).to be_truthy
    end
  end
end