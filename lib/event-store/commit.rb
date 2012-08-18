module EventStore
  # Represents a series of events which have been fully committed as a single unit and which apply to the stream indicated.
  class Commit
    def initialize(hash)
      attributes = {
        :stream_id        => nil,
        :commit_id        => nil,
        :commit_sequence  => 1,
        :stream_revision  => 1,
        :commit_timestamp => Time.now.utc,
        :events           => []
      }
      # Assigning only declared attributes
      values = attributes.merge hash
      attributes.keys.each { |key| instance_variable_set "@#{key}", values[key] }
    end
    
    # Gets the value which uniquely identifies the stream to which the commit belongs.
    attr_reader :stream_id

    # Gets the value which uniquely identifies the commit within the stream.
    attr_reader :commit_id

    # Gets the value which indicates the sequence (or position) in the stream to which this commit applies.
    attr_reader :commit_sequence
    
    # Gets the value which indicates the revision of the most recent event in the stream to which this commit applies.
    # In case each commit in the stream has one event then stream_revision == commit_sequence
    # In case some commits have more then one events then stream_revision > commit_sequence
    attr_reader :stream_revision

    # Gets the point in time at which the commit was persisted.
    attr_reader :commit_timestamp

    # Gets the collection of event messages to be committed as a single unit.
    attr_reader :events
    
    def ==(other)
      @stream_id == other.stream_id && @commit_id == other.commit_id
    end
    
    def eql?(other)
      self == other
    end
    
    def to_s
      %(Commit { stream_id: #{stream_id}, commit_id: #{commit_id}, commit_sequence: #{commit_sequence}, stream_revision: #{stream_revision}, events.length: #{events.length} })
    end
    
    class << self
      def build(stream, events)
        new :stream_id => stream.stream_id,
          :commit_id => Identity.generate,
          :commit_sequence => stream.commit_sequence + 1,
          :stream_revision => stream.stream_revision + events.length,
          :events => events
      end
    end
  end
end