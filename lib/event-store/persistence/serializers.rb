module EventStore::Persistence::Serializers
  class AbstractSerializer
    def serialize(object)
      self.class.serializer.dump(object)
    end
    
    def deserialize(data)
      self.class.serializer.load(data)
    end

    def self.serializer
      raise 'Not implemented'
    end
  end
  
  class MarshalSerializer < AbstractSerializer
    def self.serializer
      Marshal
    end
  end
  
  class JsonSerializer < AbstractSerializer
    def self.serializer
      require 'json' unless defined?(JSON)
      return JSON
    end
  end
  
  class YamlSerializer < AbstractSerializer
    def self.serializer
      require 'yaml' unless defined?(YAML)
      return YAML
    end
  end
  
  class GzipSerializer < AbstractSerializer
    def initialize(inner)
      @inner = inner
    end
    
    def serialize(data)
      Zlib::Deflate.deflate @inner.serialize data
    end
    
    def deserialize(data)
      @inner.deserialize Zlib::Inflate.inflate data
    end
  end
end