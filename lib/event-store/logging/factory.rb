module Xtms::EventStore::Logging
  class Factory
    def self.logger(name)
      ConsoleLogger.new(name)
    end
  end
  
  class ConsoleLogger
    def initialize(name)
      @name = name
    end
    
    def debug(message)
      $stdout.puts format_message("DEBUG", message)
    end
    
    def info(message)
      $stdout.puts format_message("INFO", message)
    end
    
    def warn(message)
      $stderr.puts format_message("WARN", message)
    end
    
    def error(message)
      $stderr.puts format_message("ERROR", message)
    end
    
    def fatal(message)
      $stderr.puts format_message("FATAL", message)
    end
    
    private
      def format_message(level, message)
        "[#{level} #{@name}] #{message}"
      end
  end
end