require 'spec-helper'

describe EventStore::Persistence::Serializers::JsonSerializer do
  it_behaves_like "a serializer" do
    before(:each) do
      target_class.class_eval do
        def to_json(*args)
          {json_class: self.class, attributes: attributes}.to_json(*args)
        end
        
        def self.json_create(data)
          new(data['attributes'])
        end
      end
    end
    
    def do_serialize(object)
      JSON.dump object
    end
    
    def do_deserialize(input)
      JSON.load input
    end
  end
  
end