module EventStore::Logging
  class Logger
    Levels = [:debug, :info, :warn, :error, :fatal]
    
    def initialize(name)
      @name = name
    end
    
    Levels.each { |level|
      eval <<-EOF
      def #{level}(*args)
        self.class.factory.get(@name).#{level}(*args)
      end
      EOF
    }
     
    class << self
      attr_writer :factory
      
      def factory
        @factory || Factory
      end
      
      def get(name)
        new(name)
      end
    end
  end
end
