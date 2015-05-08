require 'spec-helper'

describe EventStore::EventStream do
  let(:transaction_context) { double(:transaction_context) }
  let(:persistence_engine) { double("persistence-engine", :commit => nil, :get_from => []) }
  let(:stream) { described_class.new("fake-stream-id", persistence_engine) }
  
  describe "add" do
    it "should add an event to an uncommitted_events list" do
      evt1 = EventStore::EventMessage.new :some_body => 1
      evt2 = EventStore::EventMessage.new :another_body => 2
      
      expect(stream.uncommitted_events).to be_empty
      
      stream.add(evt1)
      stream.add(evt2)
      
      expect(stream.uncommitted_events.length).to eql 2
      expect(stream.uncommitted_events).to include(evt1)
      expect(stream.uncommitted_events).to include(evt2)
    end
  end
  
  describe "uncommitted_events" do
    it "should be read-only array" do
      expect(stream.uncommitted_events).to be_instance_of(EventStore::Infrastructure::ReadOnlyArray)
    end
  end
  
  describe "committed_events" do
    it "should be read-only array" do
      expect(stream.committed_events).to be_instance_of(EventStore::Infrastructure::ReadOnlyArray)
    end  
  end
  
  describe "initialize" do
    it "should fail if stream-id is empty" do
      expect(lambda { described_class.new("", persistence_engine) }).to raise_error(EventStore::EventStream::InvalidStreamIdError)
      expect(lambda { described_class.new(nil, persistence_engine) }).to raise_error(EventStore::EventStream::InvalidStreamIdError)
    end
    
    it "should use persistence_engine to get all commits" do
      expect(persistence_engine).to receive(:get_from).with("fake-stream-id").and_return([])
      described_class.new("fake-stream-id", persistence_engine)
    end
    
    context "if no commits" do
      before(:each) do
        allow(persistence_engine).to receive(:get_from) { [] }
      end
      
      it "should initialize new stream" do
        expect(stream.stream_revision).to eql 0
        expect(stream.commit_sequence).to eql 0
        expect(stream.committed_events).to be_empty
        expect(stream.uncommitted_events).to be_empty
      end
      
      it "should set is new flag to true" do
        expect(stream).to be_new_stream
      end
    end
    
    describe 'if no commits but with min_revision' do
      let(:stream) { described_class.new('stream-100', persistence_engine, min_revision: 13) }
      before(:each) do
        expect(persistence_engine).to receive(:get_from).with('stream-100', min_revision: 13) { [] }
        allow(persistence_engine).to receive(:get_head).with('stream-100').and_return({commit_sequence: 321, stream_revision: 4432})
      end
      
      it 'should initialize the stream as existing stream' do
        expect(stream.new_stream?).to be_falsy
      end
      
      it 'should get stream head and initialize the stream with it' do
        expect(persistence_engine).to receive(:get_head).with('stream-100').and_return({commit_sequence: 321, stream_revision: 4432})
        expect(stream.commit_sequence).to eql 321
        expect(stream.stream_revision).to eql 4432
      end
      
      it 'should fail if min_revision is greater by more than one than stream head' do
        expect(persistence_engine).to receive(:get_head).with('stream-100').and_return({commit_sequence: 321, stream_revision: 11})
        expect { stream }.to raise_error ArgumentError, "Specified min_revision 13 is to big. Stream head revision points to 11."
      end
    end
      
    context "if there are commits" do
      let(:commit1) { double(:commit, :commit_sequence => 1, stream_revision: 2, :events => [double(:evt1), double(:evt2)]) }
      let(:commit2) { double(:commit, :commit_sequence => 2, stream_revision: 3, :events => [double(:evt1)]) }
      let(:commit3) { double(:commit, :commit_sequence => 3, stream_revision: 6, :events => [double(:evt1), double(:evt2), double(:evt3)]) }
      
      before(:each) do
        allow(persistence_engine).to receive(:get_from) { [commit1, commit2, commit3] }
      end
      
      it "should populate stream with commits" do
        expect(stream.stream_revision).to eql 6 #2 + 1 + 3
        expect(stream.commit_sequence).to eql 3 #Number of commits
        expect(stream.committed_events.length).to eql(6)
        expect(stream.uncommitted_events).to be_empty
        expect(stream.committed_events[0]).to be commit1.events[0]
        expect(stream.committed_events[1]).to be commit1.events[1]
        expect(stream.committed_events[2]).to be commit2.events[0]
        expect(stream.committed_events[3]).to be commit3.events[0]
        expect(stream.committed_events[4]).to be commit3.events[1]
        expect(stream.committed_events[5]).to be commit3.events[2]
      end
      
      it "should set is new to false" do
        expect(stream).not_to be_new_stream
      end
      
      it 'should handle min_revision option' do
        commit1 = double(:commit, commit_id: 1, :commit_sequence => 10, stream_revision: 14, :events => [double(:evt1), double(:evt2), double(:evt2)])
        commit2 = double(:commit, commit_id: 2, :commit_sequence => 11, stream_revision: 15, :events => [double(:evt1)])
        commit3 = double(:commit, commit_id: 3, :commit_sequence => 12, stream_revision: 18, :events => [double(:evt1), double(:evt2), double(:evt3)])

        expect(persistence_engine).to receive(:get_from).with('stream-100', min_revision: 13) { [commit1, commit2, commit3] }
        stream = described_class.new('stream-100', persistence_engine, min_revision: 13)
        expect(stream.stream_revision).to eql 18
        expect(stream.commit_sequence).to eql 12
        expect(stream.committed_events.length).to eql 6
        expect(stream.committed_events[0]).to be commit1.events[1]
        expect(stream.committed_events[1]).to be commit1.events[2]
        expect(stream.committed_events[2]).to be commit2.events[0]
        expect(stream.committed_events[3]).to be commit3.events[0]
        expect(stream.committed_events[4]).to be commit3.events[1]
        expect(stream.committed_events[5]).to be commit3.events[2]
      end
    end
  end
  
  describe "commit_changes" do
    it "should build commit and commit it with persistence engine" do
      evt1 = double("event-1"), evt2 = double("event-2")
      stream.add(evt1).add(evt2)
      
      attempt = double(:attempt, stream_revision: 2, :commit_id => "commit-1", :commit_sequence => 1, :events => [evt1, evt2])
      expect(EventStore::Commit).to receive(:build).with(stream, [evt1, evt2], {}).and_return(attempt)
      
      expect(persistence_engine).to receive(:commit).with(transaction_context, attempt)
      
      expect(stream.commit_changes(transaction_context)).to eql attempt
    end
    
    it "should do nothing if no uncommited_events" do
      expect(EventStore::Commit).not_to receive(:build)
      expect(persistence_engine).not_to receive(:commit)
      stream.commit_changes(transaction_context)
    end
    
    it "should populate stream with new events and remove them from uncommited" do
      commit1 = double(:commit, stream_revision: 2, :commit_id => "commit-1", :commit_sequence => 1, :events => [double(:evt1), double(:evt2)])
      commit2 = double(:commit, stream_revision: 3, :commit_id => "commit-2", :commit_sequence => 2, :events => [double(:evt1)])
      
      allow(persistence_engine).to receive(:get_from) { [commit1, commit2] }
      
      #Making sure initial conditions are met
      expect(stream.stream_revision).to eql 3
      expect(stream.commit_sequence).to eql 2
      expect(stream.uncommitted_events).to be_empty
      expect(stream.committed_events.length).to eql 3
      
      evt1 = double("event-1"), evt2 = double("event-2")
      stream.add(evt1).add(evt2)
      
      expect(stream.uncommitted_events.length).to eql 2
      
      attempt = double(:attempt, stream_revision: 5, :commit_id => "commit-2", :commit_sequence => 3, :events => [evt1, evt2])
      allow(EventStore::Commit).to receive(:build) { attempt }
      
      stream.commit_changes transaction_context
      
      expect(stream.uncommitted_events).to be_empty
      expect(stream.committed_events.length).to eql 5
      
      expect(stream.committed_events[3]).to eql evt1
      expect(stream.committed_events[4]).to eql evt2
    end
    
    it "should return committed commit with events" do
      evt1 = double("event-1"), evt2 = double("event-2")
      stream.add(evt1).add(evt2)
      
      commit = stream.commit_changes transaction_context
      expect(commit.events.length).to eql(2)
      expect(commit.events).to include evt1
      expect(commit.events).to include evt2
    end
    
    it "should invoke pipeline_hooks after commit" do
      hook1   = double(:hook1), hook2 = double(:hook2)
      stream = described_class.new(EventStore::Identity::generate, persistence_engine, :hooks => [hook1, hook2])
      attempt = double(:attempt, stream_revision: 1, :commit_id => "commit-1", :commit_sequence => 1, :events => [])
      allow(EventStore::Commit).to receive(:build) { attempt }
      stream.add(double("event-1"))
      
      expect(hook1).to receive(:post_commit).with(attempt)
      expect(hook2).to receive(:post_commit).with(attempt)
      
      stream.commit_changes transaction_context
    end

    it "should build commit with headers" do
      evt1 = double("event-1")
      stream.add(evt1)
      
      commit = stream.commit_changes transaction_context,  header1: "header-1", header2: "header-2"
      expect(commit.headers).to eql header1: "header-1", header2: "header-2"
    end
    
    it "should set is new to false" do
      stream.add(double("event-1"))
      stream.commit_changes transaction_context
      expect(stream).not_to be_new_stream
    end
  end
end
