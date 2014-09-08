module EventStore
  MAJOR = 1
  MINOR = 1
  TINY = 0
  PRE = "a"
  
  VERSION = [MAJOR, MINOR, TINY, PRE].join('.')
  
  def self.version
    VERSION
  end
end