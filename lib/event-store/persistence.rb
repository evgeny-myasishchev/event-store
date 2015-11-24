module EventStore::Persistence
  require_relative 'persistence/persistence-engine'
  require_relative 'persistence/persistence-factory'
  require_relative 'persistence/serializers'
  
  module Engines
    require_relative 'persistence/engines/in-memory-engine'
    require_relative 'persistence/engines/sql-engine'
  end
end