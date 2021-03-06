require 'spec-helper'

describe EventStore::Bootstrap do
  describe "bootstrap" do
    it "should raise BootstrapError if no persistence" do
      expect { 
        described_class.bootstrap do |with|
        end
      }.to raise_error(EventStore::Bootstrap::BootstrapError)
    end
    
    it "should create new event store" do
      store = described_class.bootstrap do |with|
        with.in_memory_persistence
      end
      expect(store).to be_instance_of(EventStore::Base)
    end
    
    describe "has_persistence_engine?" do
      it "should be true if the engine has been initialized" do
        described_class.bootstrap do |with|
          expect(with).not_to have_persistence_engine
          with.in_memory_persistence
          expect(with).to have_persistence_engine
        end
      end
    end
    
    describe "sql_persistence" do
      let(:engine_class) { EventStore::Persistence::Engines::SqlEngine }
      let(:connection_spec) { {adapter: 'sqlite', database: ':memory:'} }
      let(:options) { {opt1: 'value1'} }
      
      it "should create and init sql engine" do
        sql_engine = instance_double(engine_class)
        expect(engine_class).to receive(:new).with(connection_spec, options).and_return(sql_engine)
        expect(sql_engine).to receive(:init_engine)
        described_class.bootstrap do |with|
          engine_init = with.sql_persistence(connection_spec, options)
          expect(engine_init).to be_instance_of(EventStore::Bootstrap::SqlEngineInit)
          expect(engine_init.engine).to be sql_engine
        end
      end
      
      describe EventStore::Bootstrap::SqlEngineInit do
        let(:subject) { @subject }
        let(:engine) { subject.engine }
        let(:serializers) { EventStore::Persistence::Serializers }
        before(:each) do
          EventStore::Bootstrap.bootstrap do |with|
            @subject = with.sql_persistence(connection_spec, options)
          end
        end
        
        it "should assign json serializer when using_json_serializer" do
          expect(subject.using_json_serializer).to be subject
          expect(engine.serializer).to be_instance_of(serializers::JsonSerializer)
        end
                
        it "should assign marshal serializer when using_marshal_serializer" do
          expect(subject.using_marshal_serializer).to be subject
          expect(engine.serializer).to be_instance_of(serializers::MarshalSerializer)
        end
        
        it "should assign yaml serializer when using_yaml_serializer" do
          expect(subject.using_yaml_serializer).to be subject
          expect(engine.serializer).to be_instance_of(serializers::YamlSerializer)
        end
      end
    end
  end
end