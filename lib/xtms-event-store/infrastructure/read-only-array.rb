module Xtms::EventStore::Infrastructure
  #Wraps source array and does not allows any modification of the source instance. Only read operations are allowed.
  #Any changes on the source are automatically reflected.
  class ReadOnlyArray
    extend Forwardable
    delegate [:length, :empty?, :include?, :[], :to_s, :each] => :@source
    
    def initialize(source)
      @source = source
    end
  end
end