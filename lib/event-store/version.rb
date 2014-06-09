module EventStore
  MAJOR = 1
  MINOR = 0
  TINY = 1
  PRE = "a"
  
  VERSION = [MAJOR, MINOR, TINY, PRE].join('.')
  
  def self.version
    VERSION
  end
end