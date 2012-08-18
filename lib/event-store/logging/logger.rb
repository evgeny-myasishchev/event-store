module EventStore::Logging
  class Logger
    def debug(*args) end
    def info(*args) end
    def warn(*args) end
    def error(*args) end
    def fatal(*args) end
      
    class << self
      def factory=(value)
        @factory = value
      end
      
      def get(name)
        (@factory || Factory).logger(name)
      end
    end
  end
end
