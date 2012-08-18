class Xtms::EventStore::Identity
  require 'securerandom'
  
  #Generates random identity
  def self.generate
    SecureRandom.uuid
  end
  
end