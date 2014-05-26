module EventStore
  MAJOR = 0
  MINOR = 1
  TINY = 1
  PRE = "a"
  
  VERSION = [MAJOR, MINOR, TINY, PRE].join('.')
  
  def self.version
    VERSION
  end
end