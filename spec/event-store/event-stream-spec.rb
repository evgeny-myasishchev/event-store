require 'spec-helper'

describe EventStore::EventStream do
  let(:persistence_engine) { mock("persistence-engine", :commit => nil, :get_from => []) }
  let(:stream) { described_class.new("fake-stream-id", persistence_engine) }
  
  describe "initialize" do
    it "should fail if stream-id is empty" do
      lambda { described_class.new("", persistence_engine) }.should raise_error(EventStore::EventStream::InvalidStreamIdError)
      lambda { described_class.new(nil, persistence_engine) }.should raise_error(EventStore::EventStream::InvalidStreamIdError)
    end
  end
  
  describe "add" do
    it "should add an event to an uncommitted_events list" do
      evt1 = EventStore::EventMessage.new :some_body => 1
      evt2 = EventStore::EventMessage.new :another_body => 2
      
      stream.uncommitted_events.should be_empty
      
      stream.add(evt1)
      stream.add(evt2)
      
      stream.uncommitted_events.length.should eql 2
      stream.uncommitted_events.should include(evt1)
      stream.uncommitted_events.should include(evt2)
    end
  end
  
  describe "uncommitted_events" do
    it "should be read-only array" do
      stream.uncommitted_events.should be_instance_of(EventStore::Infrastructure::ReadOnlyArray)
    end
  end
  
  describe "committed_events" do
    it "should be read-only array" do
      stream.committed_events.should be_instance_of(EventStore::Infrastructure::ReadOnlyArray)
    end  
  end
  
  describe "initialize" do
    it "should use persistence_engine to get all commits" do
      persistence_engine.should_receive(:get_from).with("fake-stream-id").and_return([])
      described_class.new("fake-stream-id", persistence_engine)
    end
    
    context "if no commits" do
      it "should initialize new stream" do
        persistence_engine.stub(:get_from) { [] }
        stream.stream_revision.should eql 0
        stream.commit_sequence.should eql 0
        stream.committed_events.should be_empty
        stream.uncommitted_events.should be_empty
      end
    end  
      
    context "if there are commits" do
      it "should populate stream with commits" do
        commit1 = mock(:commit, :commit_sequence => 1, :events => [mock(:evt1), mock(:evt2)])
        commit2 = mock(:commit, :commit_sequence => 2, :events => [mock(:evt1)])
        commit3 = mock(:commit, :commit_sequence => 3, :events => [mock(:evt1), mock(:evt2), mock(:evt3)])
        
        persistence_engine.stub(:get_from) { [commit1, commit2, commit3] }
        stream.stream_revision.should eql 6 #2 + 1 + 3
        stream.commit_sequence.should eql 3 #Number of commits
        stream.committed_events.should have(6).items
        stream.uncommitted_events.should be_empty
        stream.committed_events[0].should be commit1.events[0]
        stream.committed_events[1].should be commit1.events[1]
        stream.committed_events[2].should be commit2.events[0]
        stream.committed_events[3].should be commit3.events[0]
        stream.committed_events[4].should be commit3.events[1]
        stream.committed_events[5].should be commit3.events[2]
      end
    end
  end
  
  describe "commit_changes" do
    it "should build commit and commit it with persistence engine" do
      evt1 = mock("event-1"), evt2 = mock("event-2")
      stream.add(evt1).add(evt2)
      
      attempt = mock(:attempt, :commit_id => "commit-1", :commit_sequence => 1, :events => [evt1, evt2])
      EventStore::Commit.should_receive(:build).with(stream, [evt1, evt2], {}).and_return(attempt)
      
      persistence_engine.should_receive(:commit).with(attempt)
      
      stream.commit_changes.should eql attempt
    end
    
    it "should do nothing if no uncommited_events" do
      EventStore::Commit.should_not_receive(:build)
      persistence_engine.should_not_receive(:commit)
      stream.commit_changes
    end
    
    it "should populate stream with new events and remove them from uncommited" do
      commit1 = mock(:commit, :commit_id => "commit-1", :commit_sequence => 1, :events => [mock(:evt1), mock(:evt2)])
      commit2 = mock(:commit, :commit_id => "commit-2", :commit_sequence => 2, :events => [mock(:evt1)])
      
      persistence_engine.stub(:get_from) { [commit1, commit2] }
      
      #Making sure initial conditions are met
      stream.stream_revision.should eql 3
      stream.commit_sequence.should eql 2
      stream.uncommitted_events.should be_empty
      stream.committed_events.length.should eql 3
      
      evt1 = mock("event-1"), evt2 = mock("event-2")
      stream.add(evt1).add(evt2)
      
      stream.uncommitted_events.length.should eql 2
      
      attempt = mock(:attempt, :commit_id => "commit-2", :commit_sequence => 3, :events => [evt1, evt2])
      EventStore::Commit.stub(:build) { attempt }
      
      stream.commit_changes
      
      stream.uncommitted_events.should be_empty
      stream.committed_events.length.should eql 5
      
      stream.committed_events[3].should eql evt1
      stream.committed_events[4].should eql evt2
    end
    
    it "should return committed commit with events" do
      evt1 = mock("event-1"), evt2 = mock("event-2")
      stream.add(evt1).add(evt2)
      
      commit = stream.commit_changes
      commit.events.should have(2).items
      commit.events.should include evt1
      commit.events.should include evt2
    end
    
    it "should invoke pipeline_hooks after commit" do
      hook1   = mock(:hook1), hook2 = mock(:hook2)
      stream = described_class.new(EventStore::Identity::generate, persistence_engine, :hooks => [hook1, hook2])
      attempt = mock(:attempt, :commit_id => "commit-1", :commit_sequence => 1, :events => [])
      EventStore::Commit.stub(:build) { attempt }
      stream.add(mock("event-1"))
      
      hook1.should_receive(:post_commit).with(attempt)
      hook2.should_receive(:post_commit).with(attempt)
      
      stream.commit_changes
    end

    it "should build commit with headers" do
      evt1 = mock("event-1")
      stream.add(evt1)
      
      commit = stream.commit_changes header1: "header-1", header2: "header-2"
      commit.headers.should eql header1: "header-1", header2: "header-2"
    end
  end
end
