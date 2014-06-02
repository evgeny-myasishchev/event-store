require 'spec-helper'

describe EventStore::Persistence::Serializers::YamlSerializer do
  it_behaves_like "a serializer" do
    def do_serialize(object)
      YAML.dump object
    end
    
    def do_deserialize(input)
      YAML.load input
    end
  end
  
end