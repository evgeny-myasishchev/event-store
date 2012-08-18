require 'rubygems'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup'

#Configure logging
require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/rollingfileoutputter'
log4r_config = YAML.load_file(File.expand_path('../log4r.yml', __FILE__))
Log4r::YamlConfigurator.decode_yaml(log4r_config['log4r_config'])

require 'xtms-event-store'

module Sample
  include EventStore
  Log = Logging::Logger.get 'xtms-event-store::sample'
  
  class EmployeeHired
    attr_reader :id
    attr_reader :full_name
    def initialize(id, full_name)
      @id, @full_name = id, full_name
    end
    
    def to_s
      "EmployeeHired { id: #{id}; full_name: #{full_name} }"
    end
  end
  
  class EmployeeResigned
    attr_reader :id
    attr_reader :reason
    def initialize(id, reason)
      @id, @reason = id, reason
    end
    
    def to_s
      "EmployeeResigned { id: #{id}; reason: #{reason} }"
    end
  end
  
  def self.init_store
    store = EventStore::Bootstrap.store do |with|
      with.log4r_logging
      with.sql_persistence adapter: 'sqlite', database: 'db/event-store.sqlite3'
      with.synchorous_dispatcher do |commit|
        commit.events.each { |event| Log.debug "Dispatching event: #{event.body}" }
      end
    end
  end
  
  def self.hire_employee store, full_name
    employee_id = Identity.generate
    stream = store.open_stream(employee_id)
    stream.add EventMessage.new EmployeeHired.new(employee_id, full_name)
    stream.commit_changes
    employee_id
  end
    
  def self.resign_employee store, employee_id, reason
    stream = store.open_stream(employee_id)
    stream.add EventMessage.new EmployeeResigned.new(employee_id, reason)
    stream.commit_changes
    employee_id
  end
end

store = Sample.init_store
employee_id = Sample.hire_employee store, "Vladimir"
Sample.resign_employee store, employee_id, "Google has hired him :("
