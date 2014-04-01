Gem::Specification.new do |s|
  s.name        = 'event-store'
  s.version     = '0.0.4a'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Evgeny Myasishchev']
  s.email       = ['evgeny.myasishchev@gmail.com']
  s.summary     = "Event store."
  s.description = "Event store implementation. Inspired by https://github.com/NEventStore/NEventStore."
  s.homepage    = 'https://github.com/evgeny-myasishchev/event-store'
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir['spec/**/*']
  
  s.add_dependency 'sequel'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'log4r'
  s.add_development_dependency 'sqlite3'
end