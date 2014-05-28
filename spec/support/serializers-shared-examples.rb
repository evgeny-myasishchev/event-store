require 'spec-helper'

shared_examples "a serializer" do
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
      'field1' => 'value-1',
      'field2'=> 'value-2'
    }
  }
  let(:target_object) { target_class.new target_attributes }
  
  def do_serialize(object)
    raise "Not implemented"
  end
  
  def do_deserialize(input)
    raise "Not implemented"
  end
  
  describe "serialize" do
    it "should dump the object" do
      actual = do_deserialize subject.serialize(target_object)
      actual.attributes.should eql target_object.attributes
    end
  end
  
  describe "deserialize" do
    it "should load the serialized object" do
      actual = subject.deserialize do_serialize(target_object)
      actual.should be_instance_of(target_class)
      actual.attributes.should eql target_object.attributes
    end
  end
end