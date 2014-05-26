require 'spec-helper'

describe EventStore::Persistence::Serializers::MarshalSerializer do
  let(:target_class) {
    class TargetClass
      attr_reader :attributes
      def initialize(attributes)
        @attributes = attributes
      end
    end
    TargetClass
  }
  let(:target_attributes) {
    {
      field1: 'value-1',
      field2: 'value-2'
    }
  }
  let(:target_object) { target_class.new target_attributes }
  
  describe "serialize" do
    it "should dump the object using Marshal" do
      actual = Marshal.load subject.serialize(target_object)
      actual.attributes.should eql target_object.attributes
    end
  end
  
  describe "deserialize" do
    it "should load the object using Marshal" do
      actual = subject.deserialize Marshal.dump(target_object)
      actual.attributes.should eql target_object.attributes
    end
  end
end