module Xtms::EventStore::Persistence
  #Factory that is used to create stream persistence engines
  class PersistenceFactory
    #Builds a persistence engine.
    def build_engine
      raise "Not implemented"
    end
  end
end