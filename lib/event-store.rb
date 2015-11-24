module EventStore
  class ConcurrencyError < StandardError 
  end
  
  module Infrastructure
    require_relative 'event-store/infrastructure/read-only-array'
  end
  
  module Logging
    require_relative 'event-store/logging/logger'
    require_relative 'event-store/logging/factory'
    require_relative 'event-store/logging/log4r-factory'
  end
  
  require_relative 'event-store/base'
  require_relative 'event-store/bootstrap'
  require_relative 'event-store/commit'
  require_relative 'event-store/event-stream'
  require_relative 'event-store/identity'
  require_relative 'event-store/persistence'
  
  class << self
    def bootstrap(&block)
      Bootstrap.bootstrap(&block)
    end
  end
end