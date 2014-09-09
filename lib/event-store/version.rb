module EventStore
  MAJOR = 1
  MINOR = 1
  TINY = 0
  
  VERSION = [MAJOR, MINOR, TINY].join('.')
  
  def self.version
    VERSION
  end
end