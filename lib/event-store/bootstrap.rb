module EventStore
	class Bootstrap
    class BootstrapError < ::StandardError
    end
    
    def self.bootstrap(&block)
      with = With.new &block
      raise BootstrapError.new "Persistence has not been initialized" if with.persistence_engine.nil?
      raise BootstrapError.new "Dispatcher has not been initialized" if with.dispatcher.nil?
      store = EventStore::Base.new with.persistence_engine, with.dispatcher
      store
    end

    class With
      attr_reader :persistence_engine
      attr_reader :dispatcher

      def initialize(&block)
        yield(self)
      end
      
      def logging(factory)
        Logging::Logger.factory = factory
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

      # &receiver should accept single argument the commit to dispatch.
      def synchorous_dispatcher(&receiver)
        @dispatcher = Dispatcher::SynchronousDispatcher.new(&receiver)
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
    end
  end
end