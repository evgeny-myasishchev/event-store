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

      def in_memory_persistence
        @persistence_engine = Persistence::Engines::InMemoryEngine.new
      end

      def sql_persistence connection_specification, options = {}
        @persistence_engine = Persistence::Engines::SqlEngine.new connection_specification, options
        @persistence_engine.init_engine
        @persistence_engine
      end

      # &receiver should accept single argument the commit to dispatch.
      def synchorous_dispatcher(&receiver)
        @dispatcher = Dispatcher::SynchronousDispatcher.new(&receiver)
      end
    end
  end
end