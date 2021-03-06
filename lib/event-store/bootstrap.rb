module EventStore
	class Bootstrap
    class BootstrapError < ::StandardError
    end
    
    def self.bootstrap(&block)
      with = With.new &block
      raise BootstrapError.new "Persistence has not been initialized" if with.persistence_engine.nil?
      store = EventStore::Base.new with.persistence_engine
      store
    end

    class With
      attr_reader :persistence_engine

      def initialize(&block)
        yield(self)
      end
      
      def logging(factory)
        Logging::Logger.factory = factory
      end

      def console_logging
        logging(Logging::Factory)
      end
      
      def log4r_logging
        logging(Logging::Log4rFactory)
      end
      
      def has_persistence_engine?
        !@persistence_engine.nil?
      end

      def in_memory_persistence
        @persistence_engine = Persistence::Engines::InMemoryEngine.new
      end

      def sql_persistence connection_specification, options = {}
        @persistence_engine = Persistence::Engines::SqlEngine.new connection_specification, options
        @persistence_engine.init_engine
        SqlEngineInit.new @persistence_engine
      end
      
      def persistence persistence_engine
        @persistence_engine = persistence_engine
      end
    end
    
    class SqlEngineInit
      attr_reader :engine
      def initialize(engine)
        @engine = engine
      end
      
      def using_marshal_serializer
        @engine.serializer = Persistence::Serializers::MarshalSerializer.new
        self
      end
      
      def using_json_serializer
        @engine.serializer = Persistence::Serializers::JsonSerializer.new
        self
      end
      
      def using_yaml_serializer
        @engine.serializer = Persistence::Serializers::YamlSerializer.new
        self
      end
      
      def compress
        @engine.serializer = Persistence::Serializers::GzipSerializer.new @engine.serializer
        self
      end
    end
  end
end