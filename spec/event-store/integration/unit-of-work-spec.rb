require 'spec-helper'

describe "Integration - EventStore - Unit Of Work" do
  let(:dispatched_events) { Array.new }

  let(:event_store) {
    EventStore.bootstrap do |with|
      with.log4r_logging
      with.in_memory_persistence
      with.synchorous_dispatcher do |commit|
        commit.events.each { |event| 
          @dispatch_hook.call event unless @dispatch_hook.nil?
          dispatched_events << event 
        }
      end
    end
  }

  module Events
    class EmployeeRegistered
      attr_reader :id
      def initialize(id)
        @id
      end

      def ==(other)
        @id == other.id
      end

      def eql?(other)
        self == other
      end
    end
  end

  describe EventStore::UnitOfWork do
    subject { described_class.new event_store, event_store.dispatcher_hook }

    describe "commit_changes" do
      let(:evt11) {Events::EmployeeRegistered.new 'emp-11'}
      let(:evt12) {Events::EmployeeRegistered.new 'emp-12'}
      let(:evt21) {Events::EmployeeRegistered.new 'emp-21'}
      let(:evt22) {Events::EmployeeRegistered.new 'emp-22'}
      
      it "should commit and dispatch all opened streams" do
        stream_1 = subject.open_stream('stream-1')
        stream_1.add evt11
        stream_1.add evt12

        stream_2 = subject.open_stream('stream-2')
        stream_2.add evt21
        stream_2.add evt22

        subject.commit_changes

        stream_1 = event_store.open_stream('stream-1')
        stream_1.committed_events.length.should eql(2)
        stream_1.committed_events[0].should eql evt11
        stream_1.committed_events[1].should eql evt12

        stream_2 = event_store.open_stream('stream-2')
        stream_2.committed_events.length.should eql(2)
        stream_2.committed_events[0].should eql evt21
        stream_2.committed_events[1].should eql evt22

        dispatched_events.length.should eql(4)
        dispatched_events[0].should eql evt11
        dispatched_events[1].should eql evt12
        dispatched_events[2].should eql evt21
        dispatched_events[3].should eql evt22
      end
      
      it "should commit all changes even if dispatch fails" do
        @dispatch_hook = lambda { |commit| raise "Dispatch failed" }
        
        stream_1 = subject.open_stream('stream-1')
        stream_1.add evt11
        stream_1.add evt12

        stream_2 = subject.open_stream('stream-2')
        stream_2.add evt21
        stream_2.add evt22

        lambda { subject.commit_changes }.should raise_error("Dispatch failed")
        
        stream_1 = event_store.open_stream('stream-1')
        stream_1.committed_events.length.should eql(2)
        stream_1.committed_events[0].should eql evt11
        stream_1.committed_events[1].should eql evt12

        stream_2 = event_store.open_stream('stream-2')
        stream_2.committed_events.length.should eql(2)
        stream_2.committed_events[0].should eql evt21
        
        dispatched_events.should be_empty
      end
    end
  end
end