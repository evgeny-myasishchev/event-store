require 'spec-helper'

describe EventStore::EventMessage do
  describe "eql? and ==" do
    it "should return false if target is not event message" do
      left = described_class.new "event-1", :header1 => "value1", :header2 => "value2"
      expect(left).not_to eql(test: 'value')
      expect(left == {test: 'value'}).to be_falsy
    end
    
    it "should return true if bodies and headers are eql" do
      left  = described_class.new "event-1", :header1 => "value1", :header2 => "value2"
      right = described_class.new "event-1", :header1 => "value1", :header2 => "value2"
      
      expect(left == right).to be_truthy
      expect(left).to eql right
    end
    
    it "should return false if if bodies are different" do
      left  = described_class.new "event-1", :header1 => "value1"
      right = described_class.new "event-2", :header1 => "value1"
      
      expect(left == right).to be_falsy
      expect(left).not_to eql right
    end
    
    it "should return false if headers are different" do
      left  = described_class.new "event-1", :header1 => "value1"
      right = described_class.new "event-1", :header2 => "value2"
      
      expect(left == right).to be_falsy
      expect(left).not_to eql right
    end
  end
  
  describe "json serialization" do
    it "should serialize headers and the body to json" do
      the_event = described_class.new({'body' => 'body1'}, {'header1' => 'header-1', 'header2' => 'header-2'})
      json = the_event.to_json
      actual = JSON.load json
      expect(actual).to be_instance_of(described_class)
      expect(actual).to eql the_event
    end
  end
end
