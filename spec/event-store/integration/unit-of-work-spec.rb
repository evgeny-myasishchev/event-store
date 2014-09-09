require 'spec-helper'

describe "Integration - EventStore - Unit Of Work" do
  let(:dispatched_events) { Array.new }

  let(:event_store) {
    EventStore.bootstrap do |with|
      with.log4r_logging
      with.in_memory_persistence
      with.synchronous_dispatcher do |commit|
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
        expect(stream_1.committed_events.length).to eql(2)
        expect(stream_1.committed_events[0]).to eql evt11
        expect(stream_1.committed_events[1]).to eql evt12

        stream_2 = event_store.open_stream('stream-2')
        expect(stream_2.committed_events.length).to eql(2)
        expect(stream_2.committed_events[0]).to eql evt21
        expect(stream_2.committed_events[1]).to eql evt22

        expect(dispatched_events.length).to eql(4)
        expect(dispatched_events[0]).to eql evt11
        expect(dispatched_events[1]).to eql evt12
        expect(dispatched_events[2]).to eql evt21
        expect(dispatched_events[3]).to eql evt22
      end
      
      it "should commit all changes even if dispatch fails" do
        @dispatch_hook = lambda { |commit| raise "Dispatch failed" }
        
        stream_1 = subject.open_stream('stream-1')
        stream_1.add evt11
        stream_1.add evt12

        stream_2 = subject.open_stream('stream-2')
        stream_2.add evt21
        stream_2.add evt22

        expect(lambda { subject.commit_changes }).to raise_error("Dispatch failed")
        
        stream_1 = event_store.open_stream('stream-1')
        expect(stream_1.committed_events.length).to eql(2)
        expect(stream_1.committed_events[0]).to eql evt11
        expect(stream_1.committed_events[1]).to eql evt12

        stream_2 = event_store.open_stream('stream-2')
        expect(stream_2.committed_events.length).to eql(2)
        expect(stream_2.committed_events[0]).to eql evt21
        
        expect(dispatched_events).to be_empty
      end
    end
  end
end