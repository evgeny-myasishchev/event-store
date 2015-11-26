require 'spec-helper'

describe EventStore::Commit do
  include Support::CommitsHelper
  
  describe "eql? and ==" do
    it "should return true if both classes are Commit instances of the same stream and same commit_id" do
      left = described_class.new :stream_id => "stream-1", :commit_id => "commit-1"
      right = described_class.new :stream_id => "stream-1", :commit_id => "commit-1"
      expect(left == right).to be_truthy
      expect(left).to eql right
    end
    
    it "should return false commit_ids are different" do
      left = described_class.new :stream_id => "stream-1", :commit_id => "commit-1"
      right = described_class.new :stream_id => "stream-1", :commit_id => "commit-2"
      expect(left == right).to be_falsy
      expect(left).not_to eql right
    end
    
    it "should return false streams are different" do
      left = described_class.new :stream_id => "stream-1", :commit_id => "commit-1"
      right = described_class.new :stream_id => "stream-2", :commit_id => "commit-1"
      expect(left == right).to be_falsy
      expect(left).not_to eql right
    end
  end
  
  describe "build" do
    it "should create a new commit from provided stream events and headers" do
      stream = instance_double(EventStore::EventStream, :stream_id => "some-stream-id", :commit_sequence => 102, :stream_revision => 23)
      evt1 = "evt1"
      evt2 = "evt2"
      
      expect(EventStore::Identity).to receive(:generate).once.and_return("new-commit-id")
      
      commit = described_class.build(stream, [evt1, evt2], header1: "header 1", header2: "header 2")
      expect(commit.stream_id).to eql "some-stream-id"
      expect(commit.commit_id).to eql "new-commit-id"
      expect(commit.commit_sequence).to eql 103
      expect(commit.stream_revision).to eql 25
      expect(commit.events.length).to eql(2)
      expect(commit.events[0]).to eql evt1
      expect(commit.events[1]).to eql evt2
      expect(commit.headers).to eql(header1: "header 1", header2: "header 2")
    end
  end
end