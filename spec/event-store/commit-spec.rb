require 'spec-helper'

describe EventStore::Commit do
  include Support::CommitsHelper
  
  describe "eql? and ==" do
    it "should return true if both classes are Commit instances of the same stream and same commit_id" do
      left = described_class.new :stream_id => "stream-1", :commit_id => "commit-1"
      right = described_class.new :stream_id => "stream-1", :commit_id => "commit-1"
      left.should == right
      left.should eql right
    end
    
    it "should return false commit_ids are different" do
      left = described_class.new :stream_id => "stream-1", :commit_id => "commit-1"
      right = described_class.new :stream_id => "stream-1", :commit_id => "commit-2"
      left.should_not == right
      left.should_not eql right
    end
    
    it "should return false streams are different" do
      left = described_class.new :stream_id => "stream-1", :commit_id => "commit-1"
      right = described_class.new :stream_id => "stream-2", :commit_id => "commit-1"
      left.should_not == right
      left.should_not eql right
    end
  end
  
  describe "build" do
    it "should create a new commit from provided stream events and headers" do
      stream = double(:stream, :stream_id => "some-stream-id", :commit_sequence => 102, :stream_revision => 23)
      evt1 = new_event("evt1")
      evt2 = new_event("evt2")
      
      EventStore::Identity.should_receive(:generate).once.and_return("new-commit-id")
      
      commit = described_class.build(stream, [evt1, evt2], header1: "header 1", header2: "header 2")
      commit.stream_id.should eql "some-stream-id"
      commit.commit_id.should eql "new-commit-id"
      commit.commit_sequence.should eql 103
      commit.stream_revision.should eql 25
      commit.events.should have(2).items
      commit.events[0].should eql evt1
      commit.events[1].should eql evt2
      commit.headers.should eql(header1: "header 1", header2: "header 2")
    end
  end
end