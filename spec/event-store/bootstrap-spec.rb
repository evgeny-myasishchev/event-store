require 'spec-helper'

describe EventStore::Bootstrap do
  describe "bootstrap" do
    it "should raise BootstrapError if no persistence" do
      lambda { 
        described_class.bootstrap do |with|
          with.synchorous_dispatcher {}
        end
      }.should raise_error(EventStore::Bootstrap::BootstrapError)
    end
    
    it "should raise BootstrapError if no dispatcher" do
      lambda { 
        described_class.bootstrap do |with|
          with.in_memory_persistence
        end
      }.should raise_error(EventStore::Bootstrap::BootstrapError)
    end
    
    it "should create new event store" do
      store = described_class.bootstrap do |with|
        with.in_memory_persistence
        with.synchorous_dispatcher {}
      end
      store.should be_instance_of(EventStore::Base)
    end
    
    describe "has_persistence_engine?" do
      it "should be true if the engine has been initialized" do
        described_class.bootstrap do |with|
          with.should_not have_persistence_engine
          with.in_memory_persistence
          with.should have_persistence_engine
          with.synchorous_dispatcher {}
        end
      end
    end
    
    it "should not dispatch_undispatched immediatelly" do
      store = double(:store)
      EventStore::Base.stub(:new) {store}
      store.should_not_receive(:dispatch_undispatched)
      described_class.bootstrap do |with|
        with.in_memory_persistence
        with.synchorous_dispatcher {}
      end
    end
    
    describe "sql_persistence" do
      let(:engine_class) { EventStore::Persistence::Engines::SqlEngine }
      let(:connection_spec) { {adapter: 'sqlite', database: ':memory:'} }
      let(:options) { {opt1: 'value1'} }
      
      it "should create and init sql engine" do
        sql_engine = double(:sql_engine)
        engine_class.should_receive(:new).with(connection_spec, options).and_return(sql_engine)
        sql_engine.should_receive(:init_engine)
        described_class.bootstrap do |with|
          engine_init = with.sql_persistence(connection_spec, options)
          engine_init.should be_instance_of(EventStore::Bootstrap::SqlEngineInit)
          engine_init.engine.should be sql_engine
          with.synchorous_dispatcher {}
        end
      end
      
      describe EventStore::Bootstrap::SqlEngineInit do
        let(:subject) { @subject }
        let(:engine) { subject.engine }
        let(:serializers) { EventStore::Persistence::Serializers }
        before(:each) do
          EventStore::Bootstrap.bootstrap do |with|
            @subject = with.sql_persistence(connection_spec, options)
            with.synchorous_dispatcher {}
          end
        end
        
        it "should assign json serializer when using_json_serializer" do
          subject.using_json_serializer.should be subject
          engine.serializer.should be_instance_of(serializers::JsonSerializer)
        end
                
        it "should assign marshal serializer when using_marshal_serializer" do
          subject.using_marshal_serializer.should be subject
          engine.serializer.should be_instance_of(serializers::MarshalSerializer)
        end
        
        it "should assign yaml serializer when using_yaml_serializer" do
          subject.using_yaml_serializer.should be subject
          engine.serializer.should be_instance_of(serializers::YamlSerializer)
        end
      end
    end
  end
end