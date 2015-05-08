module EventStore
  MAJOR = 3
  MINOR = 0
  PATCH = 1
  BUILD = 'b1'
  
  VERSION = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  
  def self.version
    VERSION
  end
end