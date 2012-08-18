Gem::Specification.new do |s|
  s.name        = 'xtms-event-store'
  s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Evgeny Myasishchev', 'Vladimir Ikryanov']
  s.email       = ['info@infora.com.ua']
  s.summary     = "Event store for XTMS."
  s.description = "Event store implementation. Inspired by https://github.com/joliver/EventStore."
  s.homepage    = 'http://infora.com.ua/xtms'
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir['spec/**/*']
  
  s.add_dependency 'sequel'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'log4r'
  s.add_development_dependency 'sqlite3'
end
