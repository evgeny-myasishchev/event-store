module EventStore::Logging
  class Log4rFactory
    def self.get(name)
      Log4r::Logger[name] || Log4r::Logger.new(name)
    end
  end
end