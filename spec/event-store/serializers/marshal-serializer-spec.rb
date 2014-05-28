require 'spec-helper'

describe EventStore::Persistence::Serializers::MarshalSerializer do
  it_behaves_like "a serializer" do
    def do_serialize(object) 
      Marshal.dump(object) 
    end
    def do_deserialize(input) 
      Marshal.load input
    end
  end
end