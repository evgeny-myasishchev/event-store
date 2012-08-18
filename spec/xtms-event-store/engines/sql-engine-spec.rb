gem 'sqlite3'
require 'spec-helper'

describe EventStore::Persistence::Engines::SqlEngine do
  include Support::CommitsHelper
  let(:engine) { described_class.new({adapter: "sqlite", database: ":memory:"}, {:orm_log_level => :debug}) }
  subject {
    engine.init_engine
    engine
  }
  
  describe "schema" do
    it "should have event-store-commits talbe created" do
      subject.connection.tables.should include :'event-store-commits'
    end
    
    def check_column(name, columns, &block)
      col = columns.detect { |c| c[0] == name }
      col.should_not be_nil, "Column '#{name}' not found."
      yield(col[1])
    end
    
    it "should have all columns to store commit" do
      columns = subject.connection.schema(:'event-store-commits')
      
      check_column(:stream_id, columns) do |column|
        column[:allow_null].should be_false
        column[:type].should eql :string
      end
      
      check_column(:commit_id, columns) do |column|
        column[:allow_null].should be_false
        column[:primary_key].should be_true
        column[:type].should eql :string
      end
            
      check_column(:commit_sequence, columns) do |column|
        column[:allow_null].should be_false
        column[:type].should eql :integer
      end

      check_column(:stream_revision, columns) do |column|
        column[:allow_null].should be_false
        column[:type].should eql :integer
      end
      
      check_column(:commit_timestamp, columns) do |column|
        column[:allow_null].should be_false
        column[:type].should eql :datetime
      end
      
      check_column(:has_been_dispatched, columns) do |column|
        column[:allow_null].should be_false
        column[:type].should eql :boolean
      end
      
      check_column(:events, columns) do |column|
        column[:allow_null].should be_false
        column[:type].should eql :blob
      end
    end
    
    it "stream_id column should be indexed" do
      indices = subject.connection.indexes(:'event-store-commits')
      indices.key?(:"event-store-commits_stream_id_index").should be_true
      indices[:"event-store-commits_stream_id_index"][:columns].should eql [:stream_id]
    end
  end
  
  context "not initialized" do
    it "should raise EngineNotInitialized error for all engine methods" do
      lambda { engine.get_from("some-stream-id") }.should raise_error(EventStore::Persistence::Engines::SqlEngine::EngineNotInitialized)
      lambda { engine.get_undispatched_commits }.should raise_error(EventStore::Persistence::Engines::SqlEngine::EngineNotInitialized)
      lambda { engine.mark_commit_as_dispatched(mock(:commit)) }.should raise_error(EventStore::Persistence::Engines::SqlEngine::EngineNotInitialized)
      lambda { engine.commit(mock(:commit)) }.should raise_error(EventStore::Persistence::Engines::SqlEngine::EngineNotInitialized)
    end
  end
  
  describe "commit" do
    it "inserts the record into the database with dispatched flag set to false" do
      attempt = build_commit("stream-1", "commit-1", new_event("event-1"), new_event("event-2"))
      subject.commit attempt
      
      table = subject.connection[:'event-store-commits']
      table.count.should eql 1
      commit = table.first
      commit[:stream_id].should eql attempt.stream_id
      commit[:commit_id].should eql attempt.commit_id
      commit[:commit_sequence].should eql attempt.commit_sequence
      commit[:stream_revision].should eql attempt.stream_revision
      #Comparing usec because it may come from the database with slightly different nsec
      commit[:commit_timestamp].usec.should eql attempt.commit_timestamp.usec
      commit[:has_been_dispatched].should be_false
      Marshal.load(commit[:events]).should eql attempt.events
    end
  end
  
  describe "mark_commit_as_dispatched" do
    it "should set dispatched flag to true" do
      attempt = build_commit("stream-1", "commit-1", new_event("event-1"), new_event("event-2"))
      subject.commit attempt
      subject.mark_commit_as_dispatched attempt
      
      commit = subject.connection[:'event-store-commits'].first
      commit[:has_been_dispatched].should be_true
    end
  end
  
  describe "purge" do
    it "should delete all items from the commits table" do
      commit1 = build_commit("stream-1", "commit-1", new_event("event-1"), new_event("event-2"))
      commit2 = build_commit("stream-2", "commit-2", new_event("event-1"), new_event("event-2"), new_event("event-3"))
      commit_all(subject, commit1, commit2)
      subject.purge
      table = subject.connection[:'event-store-commits']
      table.count.should eql 0
    end
  end
  
  it_behaves_like "generic-persistence-engine"
end