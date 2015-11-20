gem 'sqlite3'
require 'spec-helper'

describe EventStore::Persistence::Engines::SqlEngine do
  include Support::CommitsHelper
  let(:engine) { described_class.new(RSpec.configuration.database_config, {:orm_log_level => :debug}) }
  subject {
    engine.connection.drop_table?(:'event-store-commits')
    engine.init_engine
    engine.purge
    engine
  }
  
  describe "initialize" do
    it "should raise error if connection specification is nil" do
      expect(lambda { described_class.new(nil) }).to raise_error(ArgumentError, 'Connection specification can not be nil')
    end
    
    it "should have YamlSerializer as a default serializer" do
      expect(subject.serializer).to be_instance_of(EventStore::Persistence::Serializers::YamlSerializer)
    end
  end
  
  it 'should support transactions' do
    expect(subject.supports_transactions?).to be true
  end
  
  describe 'transaction' do
    it 'should start transaction and yield supplied block' do
      block_called = false
      subject.transaction do |context|
        expect(subject.connection).to be_in_transaction
        block_called = true
      end
      expect(block_called).to be true
    end
  end
  
  describe "schema" do
    it "should have event-store-commits talbe created" do
      expect(subject.connection.tables).to include :'event-store-commits'
    end
    
    def check_column(name, columns, &block)
      col = columns.detect { |c| c[0] == name }
      expect(col).not_to be_nil, "Column '#{name}' not found."
      yield(col[1])
    end
    
    it "should have all columns to store commit" do
      columns = subject.connection.schema(:'event-store-commits')
      
      check_column(:checkpoint_number, columns) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to eql :integer

        #sqlite does not support autoincrement on bigint
        #it's using for testing only so not a big deal.
        expect(column[:db_type]).to eql 'bigint' unless subject.connection.database_type == :sqlite

        expect(column[:primary_key]).to be_truthy
      end

      check_column(:stream_id, columns) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to eql :string
      end
      
      check_column(:commit_id, columns) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to eql :string
      end
            
      check_column(:commit_sequence, columns) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to eql :integer
      end

      check_column(:stream_revision, columns) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to eql :integer
      end
      
      check_column(:commit_timestamp, columns) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to eql :datetime
      end

      check_column(:headers, columns) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to eql :blob
      end
      
      check_column(:events, columns) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to eql :blob
      end
    end
  end
  
  context "not initialized" do
    it "should raise EngineNotInitialized error for all engine methods" do
      expect(lambda { engine.get_from("some-stream-id") }).to raise_error(EventStore::Persistence::Engines::SqlEngine::EngineNotInitialized)
      expect(lambda { engine.commit(double(:commit)) }).to raise_error(EventStore::Persistence::Engines::SqlEngine::EngineNotInitialized)
    end
  end
  
  describe "commit" do
    let(:attempt) { 
      build_commit("stream-1", "commit-1", new_event("event-1"), new_event("event-2")) do |a|
        a[:headers] = {header1: 'value-1', header2: 'value-2'}
      end
    }
    
    it "inserts the record into the database" do
      subject.commit attempt
      table = subject.connection[:'event-store-commits']
      expect(table.count).to eql 1
      commit = table.first
      expect(commit[:stream_id]).to eql attempt.stream_id
      expect(commit[:commit_id]).to eql attempt.commit_id
      expect(commit[:commit_sequence]).to eql attempt.commit_sequence
      expect(commit[:stream_revision]).to eql attempt.stream_revision
      #Comparing usec because it may come from the database with slightly different nsec
      expect(commit[:commit_timestamp].usec).to eql attempt.commit_timestamp.usec
    end
    
    it "uses the serializer to store events and headers" do
      expect(subject.serializer).to receive(:serialize).with(attempt.events).and_call_original
      expect(subject.serializer).to receive(:serialize).with(attempt.headers).and_call_original
      subject.commit attempt
      table = subject.connection[:'event-store-commits']
      expect(table.count).to eql 1
      commit = table.first
      serializer = described_class.default_serializer
      expect(serializer.deserialize(commit[:headers])).to eql attempt.headers
      expect(serializer.deserialize(commit[:events])).to eql attempt.events
    end
    
    it "able to store and read binary data of events and headers" do
      binary_data = []
      256.times { |b| binary_data << b }
      
      attempt = build_commit("stream-1", "commit-1", {e: 'v'})
      expect(subject.serializer).to receive(:serialize).with(attempt.events) { binary_data.pack('C*') }
      expect(subject.serializer).to receive(:serialize).with(attempt.headers) { binary_data.pack('C*') }
      subject.commit attempt
      table = subject.connection[:'event-store-commits']
      commit = table.first
      
      expect(commit[:events].unpack('C*')).to eql binary_data
      expect(commit[:headers].unpack('C*')).to eql binary_data
    end
    
    it "should raise specific ConcurrencyException if stream_revision or commit_sequence unique keys are violated" do
      commit_args = {
        :stream_id => 'stream-1',
        :commit_id => 'commit-1',
        :commit_sequence => 1,
        :stream_revision => 1
      }
      attempt = EventStore::Commit.new commit_args
      subject.commit attempt

      commit_args[:stream_revision] = 2
      attempt = EventStore::Commit.new commit_args
      
      expect { subject.commit(attempt) }.to raise_error(EventStore::ConcurrencyError)

      commit_args[:stream_revision] = 1
      commit_args[:commit_sequence] = 2
      attempt = EventStore::Commit.new commit_args
      expect { subject.commit(attempt) }.to raise_error(EventStore::ConcurrencyError)
    end
  end
  
  describe "purge" do
    it "should delete all items from the commits table" do
      commit1 = build_commit("stream-1", "commit-1", new_event("event-1"), new_event("event-2"))
      commit2 = build_commit("stream-2", "commit-2", new_event("event-1"), new_event("event-2"), new_event("event-3"))
      commit_all(subject, commit1, commit2)
      subject.purge
      table = subject.connection[:'event-store-commits']
      expect(table.count).to eql 0
    end
  end
  
  it_behaves_like "generic-persistence-engine"
end