module EventStore
  class ConcurrencyError < StandardError 
  end
  
  module Infrastructure
    autoload :ReadOnlyArray, 'event-store/infrastructure/read-only-array'
  end
  
  module Logging
    autoload :Logger, 'event-store/logging/logger'
    autoload :Factory, 'event-store/logging/factory'
    autoload :Log4rFactory, 'event-store/logging/log4r-factory'
  end
  
  autoload :Base, 'event-store/base'
  autoload :Bootstrap, 'event-store/bootstrap'
  autoload :Commit, 'event-store/commit'
  autoload :EventStream, 'event-store/event-stream'
  autoload :Identity, 'event-store/identity'
  autoload :Persistence, 'event-store/persistence'
  
  class << self
    def bootstrap(&block)
      Bootstrap.bootstrap(&block)
    end
  end
end