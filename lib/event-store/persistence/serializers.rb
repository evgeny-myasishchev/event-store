module EventStore::Persistence::Serializers
  class AbstractSerializer
    def serialize(object)
      raise 'Not implemented'
    end
    
    def deserialize(data)
      raise 'Not implemented'
    end
  end
  
  class MarshalSerializer
    def serialize(object)
      Marshal.dump(object)
    end
    
    def deserialize(data)
      Marshal.load(data)
    end
  end
end