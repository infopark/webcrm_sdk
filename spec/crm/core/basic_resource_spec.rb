module Crm; module Core

describe BasicResource do
  class Test < BasicResource; end
  class OtherTest < BasicResource; end
  class SubClassTest < Test; end
  class YetAnotherTest < BasicResource
    def self.resource_name
      "my_custom_name"
    end
  end

  describe '.resource_name' do
    it 'extracts the resource_name from the class name' do
      expect(Test.resource_name).to eq('test')
      expect(OtherTest.resource_name).to eq('other_test')
    end

    it 'allows overwriting the resource_name in subclasses' do
      expect(YetAnotherTest.resource_name).to eq('my_custom_name')
    end
  end

  describe '.path' do
    it 'extracts the path from the class name' do
      expect(Test.path).to eq('tests')
      expect(OtherTest.path).to eq('other_tests')
    end
  end

  describe '.base_type' do
    it 'extracts the base type from the class name' do
      expect(Test.base_type).to eq('Test')
      expect(OtherTest.base_type).to eq('OtherTest')
    end
  end

  describe '#path' do
    it 'returns the resource path including the ID' do
      expect(Test.new({'id' => '23'}).path).to eq('tests/23')
      expect(OtherTest.new({'id' => '42'}).path).to eq('other_tests/42')
    end

    context 'when id is nil' do
      it 'returns the resource path without ID' do
        expect(Test.new({'id' => nil}).path).to eq('tests')
        expect(OtherTest.new({'id' => nil}).path).to eq('other_tests')
      end
    end
  end

  it 'is a AttributeProvider' do
    expect(BasicResource.new({})).to be_a Mixins::AttributeProvider
  end

  describe '.initialize' do
    let(:attributes) { { 'foo' => 'bar' } }

    it 'passes its attributes to AttributeProvider#load_attributes' do
      resource = BasicResource.new(attributes)

      expect(resource.foo).to eq('bar')
    end
  end

  describe '#type' do
    let(:resource) { YetAnotherTest.new({'type_id' => 'the_first_type_id'}) }

    it 'returns the type of this resource' do
      expect(RestApi.instance).to receive(:get).with('types/the_first_type_id').and_return({
        'id' => 'the_first_type_id',
        'item_base_type' => 'Activity',
      })

      type = resource.type
      expect(type).to be_a(Crm::Type)
      expect(type.item_base_type).to eq('Activity')
    end
  end

  describe '#reload' do
    let(:resource) {
      OtherTest.new({'foo' => 'old_value', 'id' => 123})
    }

    it 'reloads the attributes from server' do
      expect(resource.foo).to eq('old_value')

      expect(RestApi.instance).to receive(:get).with('other_tests/123').and_return({'foo' => 'new_value'})
      resource.reload
      expect(resource.foo).to eq('new_value')
    end

    it 'returns itself' do
      expect(RestApi.instance).to receive(:get).and_return({})

      expect(resource.reload).to be(resource)
    end
  end

  describe '#eql? & #hash' do
    let(:test_object_with_id_23) {Test.new('id' => '23')}

    context 'when comparing with objects, that have the same class and the same id' do
      it 'is equal' do
        expect(test_object_with_id_23).to be_eql(test_object_with_id_23)
        expect(test_object_with_id_23).to be_eql(
            Test.new('id' => '23', 'additional_field' => 'ignore me'))

        expect(test_object_with_id_23.hash).to eq(Test.new('id' => '23').hash)
      end
    end

    context 'when comparing with objects, where the class and/or the id is not identical' do
      it 'is not equal' do
        expect(test_object_with_id_23).to_not be_eql(Object.new)
        expect(test_object_with_id_23).to_not be_eql(Test.new('id' => '42'))
        expect(test_object_with_id_23).to_not be_eql(OtherTest.new('id' => '23'))
        expect(test_object_with_id_23).to_not be_eql(SubClassTest.new('id' => '23'))

        expect(test_object_with_id_23.hash).to_not eq(Test.new('id' => '42').hash)
      end
    end

    it 'supports hash lookups' do
      hash = { Test.new('id' => '23') => 'foo', OtherTest.new('id' => '23') => 'bar'}
      expect(hash[Test.new('id' => '23')]).to eq('foo')
      expect(hash[Test.new('id' => '24')]).to be_nil
      expect(hash[OtherTest.new('id' => '23')]).to eq('bar')
    end
  end
end

end; end
