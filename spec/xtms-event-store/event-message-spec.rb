require 'spec-helper'

describe Xtms::EventStore::EventMessage do
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
end
