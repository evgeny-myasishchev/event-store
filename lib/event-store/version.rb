module EventStore
  MAJOR = 1
  MINOR = 1
  TINY = 3
  
  VERSION = [MAJOR, MINOR, TINY].join('.')
  
  def self.version
    VERSION
  end
end