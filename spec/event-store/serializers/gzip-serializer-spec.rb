require 'spec-helper'

describe EventStore::Persistence::Serializers::GzipSerializer do
  let(:inner) { EventStore::Persistence::Serializers::MarshalSerializer.new }
  subject { 
    described_class.new inner
  }
  
  it_behaves_like "a serializer" do
    def do_serialize(object) 
      Zlib::Deflate.deflate inner.serialize(object)
    end
    def do_deserialize(input) 
      inner.deserialize Zlib::Inflate.inflate input
    end
  end
end