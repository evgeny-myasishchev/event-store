require 'spec-helper'

describe EventStore::EventMessage do
  describe "eql? and ==" do
    it "should return true if bodies and headers are eql" do
      left  = described_class.new "event-1", :header1 => "value1", :header2 => "value2"
      right = described_class.new "event-1", :header1 => "value1", :header2 => "value2"
      
      left.should == right
      left.should eql right
    end
    
    it "should return false if if bodies are different" do
      left  = described_class.new "event-1", :header1 => "value1"
      right = described_class.new "event-2", :header1 => "value1"
      
      left.should_not == right
      left.should_not eql right
    end
    
    it "should return false if headers are different" do
      left  = described_class.new "event-1", :header1 => "value1"
      right = described_class.new "event-1", :header2 => "value2"
      
      left.should_not == right
      left.should_not eql right
    end
  end
  
  describe "json serialization" do
    it "should serialize headers and the body to json" do
      the_event = described_class.new({'body' => 'body1'}, {'header1' => 'header-1', 'header2' => 'header-2'})
      json = the_event.to_json
      actual = JSON.load json
      actual.should be_instance_of(described_class)
      actual.should eql the_event
    end
  end
end
