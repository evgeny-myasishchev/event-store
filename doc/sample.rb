require 'rubygems'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup'
require 'event-store'

module Events
  EmployeeHired = Struct.new(:id, :full_name)  
  EmployeeResigned = Struct.new(:id, :reason)
end

class EmployeesService
  include EventStore
  include Events
  
  def initialize(store)
    @store = store
  end
  
  def hire_employee full_name
    employee_id = Identity.generate
    stream = @store.create_stream(employee_id)
    stream.add EmployeeHired.new(employee_id, full_name)
    stream.commit_changes
    employee_id
  end
    
  def resign_employee employee_id, reason
    stream = @store.open_stream(employee_id)
    stream.add EmployeeResigned.new(employee_id, reason)
    stream.commit_changes
  end
end

store = EventStore.bootstrap do |with|
  with.console_logging
  with.in_memory_persistence
end

employees_service = EmployeesService.new store
employee_id = employees_service.hire_employee 'Bob'
employees_service.resign_employee employee_id, 'Found another job'

puts 'Committed events'
store.for_each_commit do |commit|
  commit.events.each do |evt|
    puts evt
  end
end