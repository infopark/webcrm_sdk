require 'spec_helper'

module Crm; module Core; module Mixins

describe Modifiable do
  class MyResource < BasicResource;
    include Modifiable
  end

  let(:now) { Time.now.utc.xmlschema }

  describe '.create' do
    it 'creates the resource' do
      expect(RestApi.instance).to receive(:post).with(
        'my_resources', {'name' => 'foo'}
      ).and_return({
        'name' => 'foo',
        'created_at' => now,
      })

      resource = MyResource.create({'name' => 'foo'})
      expect(resource.name).to eq('foo')
      expect(resource.created_at).to eq(now)
    end

    context 'without any parameter' do
      it 'creates an "empty" resource' do
        expect(RestApi.instance).to receive(:post).with(
          'my_resources', {}
        ).and_return({
          'name' => '',
          'created_at' => now,
        })

        resource = MyResource.create
        expect(resource.name).to eq('')
        expect(resource.created_at).to eq(now)
      end
    end
  end

  describe '#update' do
    let(:resource) {
      MyResource.new({
        'id' => 'abc',
        'name' => 'foo',
        'weather' => 'rainy',
        'version' => 2,
      })
    }

    it 'updates the resource' do
      expect(RestApi.instance).to receive(:put).with(
        'my_resources/abc', {'name' => 'bar'}, {'If-Match' => 2}
      ).and_return({
        'id' => 'abc',
        'name' => 'bar',
        'weather' => 'rainy',
        'updated_at' => now,
      })
      expect(resource.update({'name' => 'bar'})).to be(resource)

      expect(resource.weather).to eq('rainy')
      expect(resource.name).to eq('bar')
      expect(resource.updated_at).to eq(now)
    end

    context 'without any parameter' do
      it 'just updates the resource' do
        expect(RestApi.instance).to receive(:put).with(
          'my_resources/abc', {}, {'If-Match' => 2}
        ).and_return({
          'id' => 'abc',
          'updated_at' => now,
        })

        expect(resource.update).to be(resource)
        expect(resource.updated_at).to eq(now)
      end
    end
  end

  [:delete, :destroy].each do |method|
    describe "##{method}" do
      let(:resource) { MyResource.new({'id' => 'abc', 'name' => 'foo', 'version' => 2})}

      it 'deletes the resource' do
        expect(resource).to_not be_deleted

        expect(RestApi.instance).to receive(:delete).with(
            'my_resources/abc', nil, {'If-Match' => 2}).and_return({
          'id' => 'abc',
          'name' => 'foo',
          'deleted_at' => now,
        })
        expect(resource.public_send(method)).to be(resource)

        expect(resource.name).to eq('foo')
        expect(resource.deleted_at).to eq(now)

        expect(resource).to be_deleted
      end
    end
  end

  describe '#undelete' do
    let(:resource) { MyResource.new({'id' => 'abc', 'name' => 'foo', 'deleted_at' => now})}

    it 'undeletes the resource' do
      expect(resource).to be_deleted

      expect(RestApi.instance).to receive(:put).with('my_resources/abc/undelete', {}).and_return({
        'id' => 'abc',
        'name' => 'foo',
        'deleted_at' => nil,
      })
      expect(resource.undelete).to be(resource)

      expect(resource.name).to eq('foo')
      expect(resource.deleted_at).to be_nil

      expect(resource).to_not be_deleted
    end
  end
end

end; end; end
